echo $1
sed -i "s/=/ /" $1
sed -i 's/^.*"/#&/' $1
sed -i "s/CONFIG_//" $1
