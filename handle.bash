param_h() {
    local -a input=("$@")
    local -A aliases
    local -A arglist
    local -A req
    local inputpar
    local argindex
    local con
    local inputpar
    local argp
    local argname
    local sort
    local sortindex=1
    local isorti=1

    # Get names and aliases for parsing and validation
    for argname in "${args[@]}"; do 
	local -n arg="$argname"
	aliases["${arg[alias]}"]="$argname"
	[[ -n "${arg[required]}" ]] && req["$argname"]=1
	[[ -n "${arg[sort]}" ]] && sort["$sortindex"]="$argname" && (( sortindex++ ))
	arglist["$argname"]=1
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
}

param_t1() {
    local char
    while IFS= read -r -n1 char; do

	# make sure $char exists
	[[ -z "$char" ]] && continue

	# get $char's alias pointer
	local passed="${aliases["$char"]}"

	# make sure input isn't needed
	[[ $inputpar == "true" ]] && printf "%b" "Input must be specified after $passed.\n" && exit 1

	param_handle

    done <<< "$con"
}



param_t2() {
    local passed="$con"
    param_handle
}



param_handle() { 
    local arg
    local change

    # If $passed equals nothing or is not an arg, error
    [[ -z "$passed" || ! "${arglist["$passed"]}" ]] && printf "%b" "Unknown argument: $char.\n" && exit 1

    # point arg to the passed arg's metadata
    declare -n arg="$passed"
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

	[[ ! -f "$change" ]] && printf "%b" "File $change does not exist.\n" && exit 1

	arg[value]="$change"

    elif [[ "$type" == "directory" ]]; then

	inputpar="true"
	[[ -n "${input["$argindex"]}" ]] && change="$(realpath "${input["$argindex"]}")"

	param_changev

	[[ ! -d "$change" ]] && printf "%b" "Directory $change does not exist.\n" && exit 1

	arg[value]="$change"

    fi

    if [[ -n ${req["$passed"]} ]]; then
	[[ -z ${arg[value]} ]] && printf "%b" "You must specify $passed."
    fi
}



param_changev() {
    [[ "$change" == -* || -z "$change" ]] && printf "%b" "Input must be specified after $passed.\n" && exit 1
}



param_c() {
    if [[ "$inputpar" == "true" ]]; then
	inputpar="false"
	return
    fi

    [[ -z "${sort[@]}" ]] && printf "%b" "Unknown argument: $con.\n" && exit 1
    
    passed="${sort["$isorti"]}"
    [[ -z "$passed" ]] && printf "%b" "Unknown argument: $con.\n" && exit 1

    (( argindex-- ))
    param_handle
    (( argindex++ ))
    inputpar="false"
    (( isorti++ ))
}

param_h "$@"
