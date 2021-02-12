use libzetta::zpool::{Health, ZpoolEngine, ZpoolOpen3};
use slog::*;

fn main() {
    let plain = slog_term::PlainSyncDecorator::new(std::io::stdout());
    let logger = Logger::root(slog_term::FullFormat::new(plain).build().fuse(), o!());
    let engine = ZpoolOpen3::default();

    let pools = engine.all().expect("Can not retrieve all pools");

    info!(logger, "Logging ready!"; health=pools.iter().map(|p| p.health()).collect::<Vec<Health>>());
}
