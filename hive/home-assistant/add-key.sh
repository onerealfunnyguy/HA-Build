docker exec -it home-assistant bash
cd
ssh-keygen -t rsa
cat .ssh/id_rsa.pub | ssh shortbus@hive 'cat >> .ssh/authorized_keys'
