#!/usr/bin/env bats
load helpers

function setup() {
    stub push_info_message_list
}

# function teardown() {}

@test "#logger_info should call echo and push_info_message_list()" {
    run logger_info "INFO: foo\n\"bar\""

    echo "$output"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "$(echo -e "INFO: foo\n\"bar\"")" ]]
    stub_called_with_exactly_times push_info_message_list 1 "${FONT_COLOR_GREEN}INFO${FONT_COLOR_END}: foo\n\"bar\""
}

