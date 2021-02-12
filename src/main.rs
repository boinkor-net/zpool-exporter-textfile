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

fn one_pool_health(pool: &Zpool, health_gauges: &prometheus::IntGaugeVec) {
    let name = pool.name().to_string();
    if !is_healthy(pool.health()) {
        eprintln!(
            "pool {} is at status {:?}: {:?}",
            &name,
            pool.health(),
            pool.reason()
        );
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

fn main() {
    let engine = ZpoolOpen3::default();

    let pools = engine.all().expect("Can not retrieve all pools");
    let health_gauges = register_int_gauge_vec!(
        "zpool_health_state",
        "Health status (1 if the <pool> is at health <state>)",
        &["pool", "state"]
    )
    .expect("Can't construct zpool_health_state");

    for pool in &pools {
        one_pool_health(pool, &health_gauges);
    }
    let encoder = TextEncoder::new();
    let metrics = prometheus::gather();
    let mut stdout = std::io::stdout();
    encoder.encode(&metrics, &mut stdout).unwrap();
}
