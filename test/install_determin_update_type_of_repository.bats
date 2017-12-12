#!/usr/bin/env bats
load helpers

function setup() {
    rm -rf /var/tmp/{..?*,.[!.]*,*}
}
function teardown() {
    rm -rf /var/tmp/{..?*,.[!.]*,*}
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_JUST_CLONE if target directory was not existed.' {
    run determin_update_type_of_repository /var/tmp/dotfiles origin "https://github.com/TsutomuNakamura/dotfiles.git" master 1

    [[ "$status" -eq $GIT_UPDATE_TYPE_JUST_CLONE ]]
    [[ "$(stub_called_times git)" -eq 0 ]]
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_NOT_GIT_REPOSITORY if target directory was existed but not git repository.' {
    mkdir -p /var/tmp
    stub_and_eval git '{
        [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]] && {
            return 1        # Failer
        }
    }'
    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 1

    echo "$status"
    [[ "$status" -eq $GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_NOT_GIT_REPOSITORY ]]
    [[ $(stub_called_times git) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_NOT_GIT_REPOSITORY if target directory was existed but not git repository after the user answerd yes by the question.' {
    stub_and_eval git '{
        [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]] && {
            return 1        # Failer
        }
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ directory.* ]] && return $ANSWER_OF_QUESTION_YES
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    echo "$status"
    [[ "$status" -eq $GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_NOT_GIT_REPOSITORY ]]
    [[ $(stub_called_times git) -eq 1 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times question 1 "The directory (or file) \"/var/tmp\" is not a git repository.\nDo you want to remove it and clone the repository? [y/N]: "
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_ABOARTED if target directory was existe but not git repository after the user answerd NO by the question.' {
    stub_and_eval git '{
        [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]] && {
            return 1        # Failer
        }
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ directory.* ]] && return $ANSWER_OF_QUESTION_NO
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    [[ "$status" -eq $GIT_UPDATE_TYPE_ABOARTED ]]
    [[ $(stub_called_times git) -eq 1 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times question 1 "The directory (or file) \"/var/tmp\" is not a git repository.\nDo you want to remove it and clone the repository? [y/N]: "
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_ABOARTED if target directory was existe but not git repository after the user ABORTED by the question.' {
    stub_and_eval git '{
        [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]] && {
            return 1        # Failer
        }
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ directory.* ]] && return $ANSWER_OF_QUESTION_ABORTED
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    [[ "$status" -eq $GIT_UPDATE_TYPE_ABOARTED ]]
    [[ $(stub_called_times git) -eq 1 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times question 1 "The directory (or file) \"/var/tmp\" is not a git repository.\nDo you want to remove it and clone the repository? [y/N]: "
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE if git url was different from the parameter and need_question is 1.' {
    stub_and_eval git '{
        if [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]]; then
                echo "somebranch"        # Different from the parameter
        elif [[ "$1" == "-C" ]] && [[ "$3" == "remote" ]] && [[ "$4" == "get-url" ]]; then
            echo "git@github.com:TsutomuNakamura/dotfiles.git"    # Different from the parameter
        fi
    }'
    stub question

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 1

    echo "$status"
    [[ "$status" -eq $GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE ]]
    [[ $(stub_called_times git) -eq 2 ]]
    [[ $(stub_called_times question) -eq 0 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times git 1 -C "/var/tmp" remote get-url origin
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE if git url was different from the parameter and need_question is 0 and answered Y.' {
    stub_and_eval git '{
        if [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]]; then
                echo "somebranch"        # Different from the parameter
        elif [[ "$1" == "-C" ]] && [[ "$3" == "remote" ]] && [[ "$4" == "get-url" ]]; then
            echo "git@github.com:TsutomuNakamura/dotfiles.git"    # Different from the parameter
        fi
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ git\ repository\ located\ in\ .*$ ]] && {
            return 0
        }
        return 2
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    [[ "$status" -eq $GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE ]]
    [[ $(stub_called_times git) -eq 2 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times git 1 -C "/var/tmp" remote get-url origin
    stub_called_with_exactly_times question 1 "The git repository located in \"/var/tmp\" is refering unexpected remote \"git@github.com:TsutomuNakamura/dotfiles.git\" (expected is \"https://github.com/TsutomuNakamura/dotfiles.git\").\nDo you want to remove the git repository and reclone it newly? [y/N]: "
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE if git url was different from the parameter and need_question is 0 and answered N.' {
    stub_and_eval git '{
        if [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]]; then
                echo "somebranch"        # Different from the parameter
        elif [[ "$1" == "-C" ]] && [[ "$3" == "remote" ]] && [[ "$4" == "get-url" ]]; then
            echo "git@github.com:TsutomuNakamura/dotfiles.git"    # Different from the parameter
        fi
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ git\ repository\ located\ in\ .*$ ]] && {
            return $ANSWER_OF_QUESTION_NO    # Answer NO
        }
        return $ANSWER_OF_QUESTION_YES
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    [[ "$status" -eq $GIT_UPDATE_TYPE_ABOARTED ]]
    [[ $(stub_called_times git) -eq 2 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times git 1 -C "/var/tmp" remote get-url origin
    stub_called_with_exactly_times question 1 "The git repository located in \"/var/tmp\" is refering unexpected remote \"git@github.com:TsutomuNakamura/dotfiles.git\" (expected is \"https://github.com/TsutomuNakamura/dotfiles.git\").\nDo you want to remove the git repository and reclone it newly? [y/N]: "
}

@test '#determin_update_type_of_repository should return GIT_UPDATE_TYPE_REMOVE_THEN_CLONE_DUE_TO_WRONG_REMOTE if git url was different from the parameter and need_question is 0 and answere was aborted.' {
    stub_and_eval git '{
        if [[ "$1" == "-C" ]] && [[ "$3" == "rev-parse" ]] && [[ "$4" == "--git-dir" ]]; then
                echo "somebranch"        # Different from the parameter
        elif [[ "$1" == "-C" ]] && [[ "$3" == "remote" ]] && [[ "$4" == "get-url" ]]; then
            echo "git@github.com:TsutomuNakamura/dotfiles.git"    # Different from the parameter
        fi
    }'
    stub_and_eval question '{
        [[ "$1" =~ ^The\ git\ repository\ located\ in\ .*$ ]] && {
            return $ANSWER_OF_QUESTION_ABORTED    # Aborted
        }
        return $ANSWER_OF_QUESTION_YES
    }'

    run determin_update_type_of_repository /var/tmp origin "https://github.com/TsutomuNakamura/dotfiles.git" master 0

    [[ "$status" -eq $GIT_UPDATE_TYPE_ABOARTED ]]
    [[ $(stub_called_times git) -eq 2 ]]
    [[ $(stub_called_times question) -eq 1 ]]
    stub_called_with_exactly_times git 1 -C "/var/tmp" rev-parse --git-dir
    stub_called_with_exactly_times git 1 -C "/var/tmp" remote get-url origin
    stub_called_with_exactly_times question 1 "The git repository located in \"/var/tmp\" is refering unexpected remote \"git@github.com:TsutomuNakamura/dotfiles.git\" (expected is \"https://github.com/TsutomuNakamura/dotfiles.git\").\nDo you want to remove the git repository and reclone it newly? [y/N]: "
}

