#[test]
fn test_that_spicommand_are_recognized() {
    let commands = vec!["enable_rgb", "disable_rgb", "blink_led", "rotation", "config"];
    for command in commands {
        assert!(::SpiCommand::decode(command).is_some(),
                format!("Command {} is not implemented", command));
    }
}
