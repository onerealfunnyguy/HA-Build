cd
ssh-keygen -t rsa
cat .ssh/id_rsa.pub | ssh shortbus@hive 'cat >> .ssh/authorized_keys'
cat .ssh/id_rsa.pub | ssh shortbus@maxx 'cat >> .ssh/authorized_keys'
