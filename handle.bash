param_h() {
    local -a input=("$@")
    local -A aliases
    local -A arglist
    local -A req
    local arg
    local inputpar
    local argindex
    local displayname
    local con
    local inputpar
    local argp
    local argname
    local sort
    local sortindex=1
    local isorti=1

    param_extra=()

    # Get names and aliases for parsing and validation
    for argname in "${args[@]}"; do 
	local -n arg="$argname"
	displayname="${arg[name]:-$argname}"
	[[ -z "${arg[type]}" ]] && printf "You must specify a type for %s.\n" "$argname" && exit 1
	[[ -n "${arg[alias]}" ]] && aliases["${arg[alias]}"]="$displayname"
	arglist["$displayname"]="$argname"
	[[ -n "${arg[required]}" ]] && req["$displayname"]="$argname"
	[[ -n "${arg[sort]}" ]] && sort["$sortindex"]="$argname" && (( sortindex++ ))
    done


    # Argument index, argindex
    argindex=1
    for argp in "$@"; do
	if [[ "$argp" == --* ]]; then
	    con="${argp#--}"
	    param_t2
	elif [[ "$argp" == -* ]]; then
	    con="${argp#-}"
	    param_t1
	else
	    con="$argp"
	    param_c
	fi
	(( argindex++ ))
    done
    for displayname in "${!req[@]}"; do
	declare -n arg="${req["$displayname"]}"
	[[ -z ${arg[value]} ]] && param_msg "You must specify --%s.\n" "$displayname" && param_dexit
    done
}

param_t1() {
    local char
    while IFS= read -r -n1 char; do

	# make sure $char exists
	[[ -z "$char" ]] && continue

	# get $char's alias pointer
	local passed="${aliases["$char"]}"

	# make sure input isn't needed
	[[ $inputpar == "true" ]] && param_msg "%b" "Input must be specified after $passed.\n" && param_dexit

	param_handle

    done <<< "$con"
}



param_t2() {
    local passed="$con"
    param_handle
}



param_handle() { 
    local change

    # If $passed equals nothing or is not an arg, error
    if [[ -z "$passed" || -z "${arglist["$passed"]}" ]]; then
	param_msg "%b" "Unknown argument: ${passed:-$char}.\n"
	[[ -n "$passed" ]] && param_extra+=("${passed:--$char}")
	param_dexit || return 1
    fi

    # point arg to the passed arg's metadata
    local targetvar="${arglist["$passed"]}"	
    declare -n arg="$targetvar"
    local type="${arg[type]}"

    if [[ "$type" == "bool" ]]; then

	arg[value]="true"

    elif [[ "$type" == "string" ]]; then

	inputpar="true"
	change="${input["$argindex"]}"

	# make sure input follows, and not more flags
	param_changev

	arg[value]="$change"

    elif [[ "$type" == "count" ]]; then

	(( arg[value]++ ))

    elif [[ "$type" == "file" ]]; then

	inputpar="true"
	[[ -n "${input["$argindex"]}" ]] && change="$(realpath "${input["$argindex"]}")"

	param_changev

	[[ ! -f "$change" ]] && param_msg "%b" "File $change does not exist.\n" && param_dexit

	arg[value]="$change"

    elif [[ "$type" == "directory" ]]; then

	inputpar="true"
	[[ -n "${input["$argindex"]}" ]] && change="$(realpath "${input["$argindex"]}")"

	param_changev

	[[ ! -d "$change" ]] && param_msg "%b" "Directory $change does not exist.\n" && param_dexit

	arg[value]="$change"

    fi
}



param_changev() {
    [[ "$change" == -* || -z "$change" ]] && param_msg "%b" "Input must be specified after $passed.\n" && param_dexit
}



param_dexit() {
    [[ "$PARAM_AUTO_EXIT" != "false" ]] && exit 1
    return 1
}



param_msg() {
    [[ "$PARAM_ERROR_MSG" != "false" ]] && printf "$1" "$2"
    return 0
}



param_c() {
    if [[ "$inputpar" == "true" ]]; then
	inputpar="false"
	return
    fi

    if [[ -z "${sort[*]}" ]]; then
	param_extra+=("$con")
	return 0
    fi

    [[ -z "${sort["$isorti"]}" ]] && param_msg "%b" "Unknown argument: $con.\n" && param_dexit
    
    passed="${sort["$isorti"]}"
    if [[ -z "$passed" ]]; then
	param_msg "%b" "Unknown argument: $con.\n"
	param_dexit || return 1
    fi

    (( argindex-- ))
    param_handle || return 1
    (( argindex++ ))
    inputpar="false"
    (( isorti++ ))
}

param_h "$@"
