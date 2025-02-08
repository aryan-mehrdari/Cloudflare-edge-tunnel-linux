#!/bin/bash

# تنظیم زبان و پاکسازی صفحه
export LANG=en_US.UTF-8
clear

# حذف دایرکتوری txt اگر وجود دارد
rm -rf txt 2>/dev/null

updatezip=0
if [[ -f "txt.zip" ]]; then
    echo "Do you want to update the local txt.zip data?"
    read -p "0 not update, 1 update (default $updatezip): " updatezip
fi

if [[ "$updatezip" == "1" ]] || [[ ! -f "txt.zip" ]]; then
    echo "Downloading data files from https://zip.baipiao.eu.org"
    echo "If you are unable to download, manually access the URL and save it as txt.zip in this directory."
    curl -# -o txt.zip https://zip.baipiao.eu.org
fi

# استخراج فایل zip
7z x txt.zip -otxt -y

clear

# منو
menu=2
echo "1. Autonomous domain or region mode"
echo "2. Custom port mode"
echo "0. Exit"
read -p "Please select mode (default $menu): " menu

if [[ "$menu" == "1" ]]; then
    goto_menu1=true
elif [[ "$menu" == "2" ]]; then
    goto_menu2=true
else
    exit
fi

if [[ $goto_menu1 ]]; then
    echo "Currently available autonomous domain or region:"
    for file in txt/*.txt; do
        asn=$(basename "$file" | cut -d'-' -f1)
        echo "$asn"
    done
    
    asn=45102
    read -p "Please enter the autonomous domain or region above (default $asn): " input_asn
    asn=${input_asn:-$asn}
    
    tls=1
    read -p "Is TLS enabled? (0 to disable, 1 to enable, default $tls): " input_tls
    tls=${input_tls:-$tls}
    tlsmode=false
    [[ "$tls" == "1" ]] && tlsmode="true"
    
    echo "Currently available ports:"
    for file in txt/$asn-$tls-*; do
        port=$(basename "$file" | cut -d'-' -f3 | cut -d'.' -f1)
        echo "$port"
    done

    read -p "Please enter the detection port (default $port): " input_port
    port=${input_port:-$port}

    goto_start=true
fi

if [[ $goto_menu2 ]]; then
    tls=1
    myfg=45102
    read -p "Is TLS enabled? (0 to disable, 1 to enable, default $tls): " input_tls
    tls=${input_tls:-$tls}
    tlsmode="false"
    [[ "$tls" == "1" ]] && tlsmode="true"

    echo "Current available port:"
    for file in txt/*-$tls-*; do
        port=$(basename "$file" | cut -d'-' -f3 | cut -d'.' -f1)
        echo "$port"
    done

    read -p "Please enter the detection port (default $port): " input_port
    port=${input_port:-$port}

    cp txt/$myfg-$tls-$port.txt ip.txt 2>/dev/null
    goto_start=true
fi

if [[ $goto_start ]]; then
    max=100
    outfile="ip.csv"
    speedtest=2
    limit=20
    test=1

    [[ "$menu" == "1" ]] && file="$asn-$tls-$port.txt" || file="ip.txt"

    read -p "Maximum number of concurrent requests (default $max): " input_max
    max=${input_max:-$max}

    read -p "Output file name (default $outfile): " input_outfile
    outfile=${input_outfile:-$outfile}

    rm -f "$outfile"

    read -p "Download speed test coroutine number, set to 0 to disable speed test (default $speedtest): " input_speedtest
    speedtest=${input_speedtest:-$speedtest}

    if [[ "$speedtest" == "0" ]]; then
        mode1=true
    else
        read -p "Is the number of speed test IPs limited? (0 no limit, 1 limit, default $test): " input_test
        test=${input_test:-$test}

        if [[ "$test" == "1" ]]; then
            read -p "How many IPs can be tested by latency (default $limit): " input_limit
            limit=${input_limit:-$limit}
            mode2=true
        else
            mode1=true
        fi
    fi

    if [[ $mode1 ]]; then
        ./iptest -file=$file -port=$port -tls=$tlsmode -max=$max -outfile=$outfile -speedtest=$speedtest
    fi

    if [[ $mode2 ]]; then
        n=0
        rm -f temp
        ./iptest -file=$file -port=$port -tls=$tlsmode -max=$max -outfile=$outfile -speedtest=0
        grep "ms" "$outfile" | cut -d',' -f1 > temp
        while IFS= read -r line; do
            ((n++))
            [[ "$n" == "$limit" ]] && break
        done < temp
        ./iptest -file=temp -port=$port -tls=$tlsmode -max=$max -outfile=$outfile -speedtest=$speedtest
        rm -f temp
    fi
fi

rm -rf txt ip.txt 2>/dev/null
echo "Test completed, press any key to close the window."
read -n 1 -s
