# Boot2Root

## Project :
1. [Getting Started](#getting-started)
2. [Liens Utiles](#lien-utiles)
3. [Pistes](#pistes)
4. [Fail 1 - Bombe](writeup1.md)
5. [Fail 2 - .bash_history](writeup2.md)
6. [Fail 3 - Dirty Cow](writeup3.md)
7. [Fail 4 - System Rescue](writeup4.md)

## Getting Started : <a name="getting-started"></a>

### Kali-Linux
Cela vous donnera acces directement à un Kali-Linux qui est un linux avec des outils de hacks.

> Sans Docker:
```
source SOURCE_ME
docker run -it --rm boot2root
```

> Avec docker:
-> Download Docker for Mac from https://docs.docker.com/docker-for-mac/ \
-> Lancer les commandes suivantes dans le repo:
```
docker build --tag boot2root .
docker run -it --rm boot2root
```

(_Penser a rajouter dans le Dockerfile au fur et a mesure les packets dont on a besoin._)


### VM
-> Download ISO from https://projects.intra.42.fr/projects/boot2root
-> Lancer une VM avec VirtualBox
- [ ] Plusieurs étapes de configuration:
**Etape 1** \
![Etape1](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.10.png?raw=true)

**Etape 2** \
![Etape2](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.26.png?raw=true)

**Etape 3** \
![Etape3](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.34.png?raw=true)

**Etape 4** \
![Etape4](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.42.png?raw=true)

**Etape 5** \
![Etape5](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.49.png?raw=true)

**Etape 6** \
![Etape6](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.51.57.png?raw=true)

**Résultat** \
![Etape7](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.52.06.png?raw=true)

- [ ] Au moment de démarrer la VM, c'est a ce momement là que l'image ISO sera demandée. Cliquez sur le petit dossier puis séléctionner l'image iso souhaitée. \
![Rentrer l'image iso](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2013.52.25.png?raw=true)

- [ ] Eteindre la VM, puis:
**Créer un reseau qui fera la lien entre votre machine et la VM** \
![Créer le nouveau réseau](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2015.07.51.png?raw=true)

**Connecter le nouveau réseau à la VM** \
Dans NOM_DE_LA_VM > Configuration > Réseau \

![Connecter le réseau](https://github.com/shfranc/Boot2Root/blob/master/images/Capture%20d%E2%80%99%C3%A9cran%202019-05-03%20%C3%A0%2014.37.47.png?raw=true)

> Recupérer les adresses ip:
Selectionner la machine dans Virtual Box. Puis en haut à droite, cliquer sur "Global Tools" -> "Host Network Manager".
Dans l'onglet "Adaptateur", on a un range d'adresses.
Dans l'onglet "DHCP Server" l'adresse "Lower Adress Bound" est une adresse que l'on peut utiliser, car le serveur DHCP attribue l'adresse la plus basse en premier.


## Liens utiles <a name="liens-utiles"></a>

### Divers
```
https://fr.wikipedia.org/wiki/Ubuntu_casper
https://www.root-me.org/?lang=en
```

### Trouver des failles dans les BDD
```
http://sqlninja.sourceforge.net/
http://sqlmap.org/
```


## Pistes <a name="pistes"></a>

### Extraire les fichiers de l'ISO

`hdiutil mount BornToSecHackMe-v1.1.iso`

### Unmount de l'ISO

```
hdiutil info # donne le nom du volume (ex : /dev/disk2)
hdiutil detach [nom du volume]
```
