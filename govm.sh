function govm_help() {
    if [[ -s ${GOVM_DIR}/help.txt ]]; then
        cat ${GOVM_DIR}/help.txt
        return 0
    else
        echo "Not find help file: ${GOVM_DIR}/help.txt"
        return 1
    fi
}

function govm_version() {
    if [[ $# != 0 ]]; then
        echo "Usage: ${FUNCNAME[@]}"
        return 1
    fi

    echo "govm version 1.0.0"

    return 0
}

function govm_show_current() {
    if [[ $# != 0 ]]; then
        echo "Usage: ${FUNCNAME[@]}"
        return 1
    fi

    if [ -x ${GOVM_DIR}/go/bin/go ]; then
        ${GOVM_DIR}/go/bin/go version
        return 0
    else
        echo "Not find current golang!"
        return 2
    fi

    return 0
}

function govm_list_local() {
    if [[ $# != 0 ]]; then
        echo "Usage: ${FUNCNAME[@]}"
        return 1
    fi

    if [[ -d ${GOVM_DIR}/golang ]]; then
        for GO in $(ls ${GOVM_DIR}/golang/ | grep -oP "^go-\K[0-9.]+$"); do
            echo "v${GO}"
        done

        return 0
    else
        echo "Not find any installed golang !"
        return 2
    fi
}

function govm_list_remote_all() {
    if [[ $# != 0 ]]; then
        echo "Usage: ${FUNCNAME[@]}"
        return 1
    fi

    FILE="${GOVM_DIR}/versions.txt"

    if [[ ! -f "${FILE}" ]]; then
        echo "Not find file ${FILE} !"
        return 2
    fi

    while IFS= read -r line; do
        if [ -n "${line}" ]; then
            echo "v${line}"
        fi
    done <"${FILE}"
}

function govm_list_remote_some() {
    if [[ $# != 1 ]]; then
        echo "Usage: ${FUNCNAME[@]} <GO_VER>"
        return 1
    fi

    FILE="${GOVM_DIR}/versions.txt"
    if [[ ! -f "${FILE}" ]]; then
        echo "Not find file ${FILE} !"
        return 2
    fi

    GO_VER=$(echo "$1" | grep -oP '[0-9.]+')
    grep --color=never "^${GO_VER}$\|^${GO_VER}\." "${FILE}" | while IFS= read -r line; do
        if [ -n "${line}" ]; then
            echo "v${line}"
        fi
    done
}

function govm_install_golang_ver() {
    if [[ $# != 1 ]]; then
        echo "Usage: ${FUNCNAME[@]} <GO_VER>"
        return 1
    fi

    GO_VER=$(echo "$1" | grep -oP '[0-9.]+')
    GO_DIR="golang/go-${GO_VER}"
    GO_FILE="go${GO_VER}.linux-amd64.tar.gz"

    mkdir -p ${GOVM_DIR}/download
    wget -t 0 -c https://golang.google.cn/dl/${GO_FILE} -P ${GOVM_DIR}/download

    mkdir -p ${GOVM_DIR}/${GO_DIR}
    rm -rf ${GOVM_DIR}/${GO_DIR}/*
    tar --strip-component=1 -C ${GOVM_DIR}/${GO_DIR} -xzf ${GOVM_DIR}/download/${GO_FILE}

    if [[ $? == 0 ]]; then
        echo "Install golang ${GO_VER} OK."
        return 0
    else
        echo "Fail to install golang ${GO_VER}!"
        return 2
    fi
}

function govm_use_golang_ver() {
    if [[ $# != 1 ]]; then
        echo "Usage: ${FUNCNAME[@]} <GO_VER>"
        return 1
    fi

    GO_VER=$(echo "$1" | grep -oP '[0-9.]+')
    GO_DIR="golang/go-${GO_VER}"

    if [ -x ${GOVM_DIR}/${GO_DIR}/bin/go ]; then
        ln -snf ${GOVM_DIR}/${GO_DIR} ${GOVM_DIR}/go
        go version
        return 0
    else
        echo "Please install golang ${GO_VER} first!"
        return 2
    fi
}

function govm_delete_golang_ver() {
    if [[ $# != 1 ]]; then
        echo "Usage: ${FUNCNAME[@]} <GO_VER>"
        return 1
    fi

    GO_VER=$(echo "$1" | grep -oP '[0-9.]+')
    GO_DIR="golang/go-${GO_VER}"
    GO_FILE="go${GO_VER}.linux-amd64.tar.gz"

    rm -f ${GOVM_DIR}/download/${GO_FILE}

    if [ -x ${GOVM_DIR}/${GO_DIR}/bin/go ]; then
        rm -rf ${GOVM_DIR}/${GO_DIR}
        return 0
    else
        echo "Not find golang ${GO_VER}!"
        return 2
    fi
}

function govm_pull() {
    if [[ $# != 0 ]]; then
        echo "Usage: ${FUNCNAME[@]}"
        return 1
    fi

    echo " Updating govm ..."
    cd $(dirname $0)
    git reset --hard
    git pull

    if [[ $? -ne 0 ]]; then
        echo "Fail to update govm!"
        return 2
    else
        echo "Update govm ok"
    fi
}

function govm() {
    if [[ $# == 0 ]]; then
        govm_help
        return $?
    elif [[ $# == 1 ]]; then
        if [[ "$1" == "h" || "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
            govm_help
            return $?
        elif [[ "$1" == "v" || "$1" == "version" || "$1" == "-v" || "$1" == "--version" ]]; then
            govm_version
            return $?
        elif [[ "$1" == "c" || "$1" == "current" ]]; then
            govm_show_current
            return $?
        elif [[ "$1" == "l" || "$1" == "local" ]]; then
            govm_list_local
            return $?
        elif [[ "$1" == "r" || "$1" == "remote" ]]; then
            govm_list_remote_all
            return $?
        fi
    elif [[ $# == 2 ]]; then
        if [[ "$1" == "i" || "$1" == "install" ]]; then
            govm_install_golang_ver $2
            return $?
        elif [[ "$1" == "u" || "$1" == "use" ]]; then
            govm_use_golang_ver $2
            return $?
        elif [[ "$1" == "d" || "$1" == "delete" ]]; then
            govm_delete_golang_ver $2
            return $?
        elif [[ "$1" == "r" || "$1" == "remote" ]]; then
            govm_list_remote_some $2
            return $?
        elif [[ "$1" == "p"|| "$1" == "pull" ]]; then
            govm_pull
            return $?
        fi
    fi

    echo "Unsupported parameter: ${FUNCNAME[@]} $*"
    echo "please run: govm help"
    return 1
}

export GOPATH=${HOME}/go

# go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/
if [[ -s ${GOVM_DIR}/.env ]]; then
    vars=$(cat ${GOVM_DIR}/.env | sed '/^\s*#/d;/^\s*$/d' | xargs)
    if [[ -n "${vars}" ]]; then
        export ${vars}
    fi
fi

echo ${PATH} | grep -qv "${HOME}/go/bin" && export PATH=${HOME}/go/bin:${PATH}
if [ -n "${GOVM_DIR}" ]; then
    echo ${PATH} | grep -qv "${GOVM_DIR}/go/bin" && export PATH=${GOVM_DIR}/go/bin:${PATH}
fi
