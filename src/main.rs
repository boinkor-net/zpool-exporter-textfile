use std::{io::stdout, path::PathBuf};

use clap::Clap;
use libzetta::zpool::{Health, Zpool, ZpoolEngine, ZpoolOpen3};
use prometheus::{register_int_gauge_vec, Encoder, TextEncoder};

const ALL_HEALTH_STATUSES: &[Health] = {
    // TODO: ensure that we're listing them exhaustively; there must be
    // some macro magic I could do via a constructed closure with a match
    // in it, but I can't figure out the syntax atm.
    use Health::*;
    &[
        Online,
        Degraded,
        Faulted,
        Offline,
        Available,
        Unavailable,
        Removed,
    ]
};

/// Returns true if the health status is OK.
fn is_healthy(health: &Health) -> bool {
    match health {
        Health::Available | Health::Online => true,
        _ => false,
    }
}

fn one_pool_health(
    pool: &Zpool,
    health_gauges: &prometheus::IntGaugeVec,
    overall_health_gauges: &prometheus::IntGaugeVec,
) {
    let name = pool.name().to_string();
    let overall_gauge = overall_health_gauges.with_label_values(&[name.as_str()]);
    if !is_healthy(pool.health()) {
        eprintln!(
            "pool {} is at status {:?}: {:?}",
            &name,
            pool.health(),
            pool.reason()
        );
        overall_gauge.set(0);
    } else {
        overall_gauge.set(1);
    }
    for status in ALL_HEALTH_STATUSES {
        let health: String = format!("{:?}", status);
        let gauge = health_gauges.with_label_values(&[name.as_str(), &health]);
        if status == pool.health() {
            gauge.set(1);
        } else {
            gauge.set(0);
        }
    }
}

#[derive(Clap)]
#[clap(version = "0.1", author = "Andreas Fuchs <asf@boinkor.net>")]
struct Opts {
    /// The file to write metrics to. If omitted, writes to stdout.
    #[clap(short = 'o', long)]
    output_file: Option<PathBuf>,
}

fn main() {
    let opts: Opts = Opts::parse();
    let engine = ZpoolOpen3::default();

    let pools = engine.all().expect("Can not retrieve all pools");
    let health_gauges = register_int_gauge_vec!(
        "zpool_health_state",
        "Health status (1 if the <pool> is at health <state>)",
        &["pool", "state"]
    )
    .expect("Can't construct zpool_health_state");
    let overall_health_gauges = register_int_gauge_vec!(
        "zpool_health_level",
        "Overall health level of a pool. 0 if unhealthy, 1 if healthy.",
        &["pool"]
    )
    .expect("Can't construct zpool_health_level");

    for pool in &pools {
        one_pool_health(pool, &health_gauges, &overall_health_gauges);
    }
    let encoder = TextEncoder::new();
    let metrics = prometheus::gather();
    if let Some(file) = opts.output_file {
        let cwd = PathBuf::from("./");
        let dir = file.parent().unwrap_or(&cwd);
        let mut handle =
            tempfile::NamedTempFile::new_in(dir).expect("Could not create output handle");
        encoder.encode(&metrics, &mut handle).unwrap();
        handle
            .persist(file)
            .expect("Could not create destination file");
    } else {
        encoder.encode(&metrics, &mut stdout()).unwrap();
    }
}
