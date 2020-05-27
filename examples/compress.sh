#!/bin/bash
# Compress text-like assets:
#   zopfli: gzip compatible but more aggressive
#   brotli: (.br) optimized compression for web assets
#

cd $(dirname $0)

function fix_attr() {
    # only root can do this, in general
    if [ $(id -u) = "0" ]; then
        chown --reference="$1" "$2"
    fi

    chmod --reference="$1" "$2"
    touch --reference="$1" "$2"
}

#################################################################
# should_make src ext
#
# tests if <src.ext> exists and has same timestamp as <src>
#
function should_make() {
    local f="$1"
    local w="$1.$2"
    if [ -e "$w" ]; then
        local a=$(stat --printf="%Y" "$w")
        local b=$(stat --printf="%Y" "$f")

        if [ "$a" = "$b" ]; then
            return 1
        fi
    fi
    return 0
}

###################################################################
# pc a b
#
# calc %age b is smaller than a
#      100 * (size(a) - size(b)) / size(a)
#
function pc() {
    local f="$1"
    local t="$2"
    PRE=$(wc -c < "$f")
    POST=$(wc -c < "$t")
    echo $(awk "BEGIN { pc=100*${POST}/${PRE}; print int(100-pc) }")
}

############################################################################################
# GZIP/ZOPFLI
#
function make_gzip() {
    local dir=${1:-/var/www}
    local f

    while IFS= read -r -d $'\0' f; do
        _gzip $f
    done < <(find $dir -type f -size +500c -regextype egrep -iregex '.*\.(html|css|js|svg|json)$' -print0)
}

function _gzip() {
    local f="$1"

    if ! should_make "$f" gz; then
        return
    fi
    # some shell funties...
    ( zopfli "$f" )
    t=$(mktemp)
    gzip -6 - < "$f" > "$t"
    percent=$(pc "$t" "$f.gz")
    test $VERBOSE && echo "zopfli $f (${percent}% vs. gzip)"
    rm "$t"

    fix_attr "$f" "$f.gz"
}

##############################################################################
# BROTLI
#
function make_brotli() {
    local dir=${1:-/var/www}

    local f
    while IFS= read -r -d $'\0' f; do
        _brotli $f
    done < <(find $dir -type f -size +500c -regextype egrep -iregex '.*\.(html|css|js|svg|json)$' -print0)
}

function _brotli() {
    local f=$1

    if ! should_make "$f" br; then
        return
    fi
    # Use a temp file to ensure atomicity
    local t=$(mktemp)
    brotli --force --output="$t" "$f"

    percent=$(pc "$f.gz" "$t")
    if [ $percent -lt 0 ]; then
        test $VERBOSE && echo "brotli $f **** NOT SAVING VS GZIP (${percent}%) ****"
        rm $t
    else
        test $VERBOSE && echo "brotli $f (${percent}% vs gzip)"
        mv "$t" "$f.br"
        fix_attr "$f" "$f.br"
    fi
}

#############################################################################

VERBOSE=
tty -s && VERBOSE=1

make_gzip dist/
# Must come after gzip
make_brotli dist/

# Fixup any dud permission
find dist -type f -print0 | xargs -0 -r chmod 644
