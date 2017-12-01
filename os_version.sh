os_version=$([[ $(sw_vers -productVersion) =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})

echo $os_version
