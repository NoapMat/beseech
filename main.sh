#!/bin/bash
hrs="5"
scr="${1}"
req="${2}"

curl -sL "${scr}" -o chagg.py
curl -sL "${req}" -o requirements.txt

echo "Installing the dependencies."
pip install -r requirements.txt &>/dev/null

# run the main script
python3 chagg.py &>/dev/null &
py_pid="${!}"

dur="$(((3600 * hrs) + 1800))"
#dur="60"

for ((e=0;e<dur;e+=60)); do
    [[ ! -d "/proc/${py_pid}" ]] && { echo "An error occured with script" ; exit 0 ;}
    echo "Running Smoothly. No errors whatsoever (in $((e/60)) min/s)"
    sleep 60
done

kill "${py_pid}"
if [[ ! -d "/proc/${py_pid}" ]]; then
    kill -9 "${py_pid}"    # last resort, forcefully kill the PID
fi

# repeat the cycle
curl -sLf -H "Authorization: Bearer ${3}" \
    -H "Accept: application/vnd.github.v3+json" \
    -X POST \
    -d '{"ref":"master","inputs":{}}' "https://api.github.com/repos/NoapMat/beseech/actions/workflows/main.yaml/dispatches" \
    -o /dev/null
# inits all created files
rm requirements.txt chagg.py
