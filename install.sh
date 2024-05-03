REPO=https://gitlab.com/bitspur/community/dotstow.git

_TMP_PATH="${XDG_RUNTIME_DIR:-$([ -d "/run/user/$(id -u $USER)" ] && echo "/run/user/$(id -u $USER)" || echo ${TMP:-${TEMP:-/tmp}})}/dotstow/$$"
alias make=$(echo $(which remake 2>&1 >/dev/null && echo remake || echo $(which gmake 2>&1 >/dev/null && echo gmake || echo make)))
sudo true
rm -rf "$_TMP_PATH"
mkdir -p "$_TMP_PATH"
git clone "$REPO" "$_TMP_PATH/dotstow"
cd "$_TMP_PATH/dotstow"
make install
cd $HOME
rm -rf "$_TMP_PATH"
