#!/bin/bash
set -x

cat > /var/tmp/fix-bootstap.sh <<'EOF'
#!/bin/bash
set -x

while true; do
    NODEPROVISIONSTATE=`sed -n '/localInstance [{]/,/[}]/{
    /nodeProvisionCheckinRecord [{]/,/[}]/ {
    /status: / { p }
    /[}]/a
    }
    /[}]/a
    }' /emr/instance-controller/lib/info/job-flow-state.txt | awk ' { print $2 }'`

    if [ "$NODEPROVISIONSTATE" == "SUCCESSFUL" ]; then
        echo "Running my post provision bootstrap"
        sudo python3 -m pip install --upgrade pip
        sudo python3 -m pip uninstall -y numpy google-auth pyspark hail python37-sagemaker-pyspark  || true
        sudo python3 -m pip install numpy==1.21.6 -U
        sudo python3 -m pip install 'google-auth>=1.27.0,<2.0.0'
        sudo python3 -m pip install 'pyspark==2.3.4'
        sudo python3 -m pip install 'hail==0.2.105'
        sudo python3 -m pip install 'python37-sagemaker-pyspark==1.4.1'
        echo '-------BOOTSTRAP COMPLETE-------'

        exit
    else
        echo "Sleeping Till Node is Provisioned"
        sleep 10
    fi
done

EOF

chmod +x /var/tmp/fix-bootstap.sh
nohup /var/tmp/fix-bootstap.sh  2>&1 &

