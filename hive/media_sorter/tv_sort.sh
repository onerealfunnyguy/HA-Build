#!/bin/bash

cd /root/sort/
mv /root/done/*.mkv /root/sort/
mv /root/done/*/*.mkv /root/sort/
mv /root/done/*.avi /root/sort/
mv /root/done/*/*.avi /root/sort/
mv /root/done/*.mp* /root/sort/
mv /root/done/*/*.mp* /root/sort/
find /root/done/*/*.rar -exec unrar e {} \;
find /root/done/*.rar -exec unrar e {} \;
perl /root/sorttv/sorttv.pl

#!/bin/bash

#cd /root/sorter/
#cd /root/sort/
#find /root/done/*/*.rar -exec unrar e {} \;
#perl /root/sorttv/sorttv.pl
