# .bash_history

## Unmount de l'ISO

On va mount l'ISO afin d'en analyser le contenu. On lance donc la commande suivante : 

`hdiutil mount BornToSecHackMe-v1.1.iso`

L'unmount de l'ISO se trouve dans `/Volumes`, et s'appelle `BornToSec`. 
On peut donc copier `BornToSec` vers un dossier de notre choix, ici Boot2Root : 

`cp -R /Volumes/BornToSec ~/PROJECTS/Boot2Root`

Le dossier BornToSec contient plusieurs fichiers et dossiers que l'on va pouvoir exploiter: 

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/1-unmount.png)

Pour ce faire, on va avoir besoin d'un Kali Linux. On lance donc le script suivant depuis notre dossier Boot2Root : 

```
source SOURCE_ME
docker run -it --mount type=bind,source="$(pwd)",target=/boot2root  --rm boot2root
```

On est alors connecté sur un Kali Linux : 

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/2-kali-linux.png)

De la, on va dans le dossier `boot2root/BornToSec` qui contient les fichiers de l'ISO. En explorant et en se renseignant sur internet (https://en.wikipedia.org/wiki/SquashFS), on se rend compte qu'un fichier est particulierement interessant : il s'agit de `filesystem.squashfs` qui se trouve dans le dossier `casper`. C'est le fichier qui contient tout le système. 

On va donc extraire le système avec `unsquashfs`. Pour ce faire on crée un dossier dans `boot2root`, et on unsquash dedans : 

```
mkdir tmp
cd tmp/
unsquashfs ../BornToSec/casper/filesystem.squashfs
```

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/3-unsquash.png)

Un dossier `squashfs-root` est maintenant disponible, contenant tout le système : 

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/4-squashfs-root.png)

Un fouillant on trouve un fichier intéressant :  `root/.bash_history`

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/5-bash_history.png)

Il s'agit de l'historique des commandes tapées par le user root. Dans le fichier on trouve : 

```
adduser zaz
646da671ca01bb5d84dbb5fb2238dc8e
```

![alt text](https://github.com/shfranc/Boot2Root/blob/master/images/6-history.png)


En ajoutant l'utilisateur zaz, root s'est trompé et a tapé le mot de passe de l'utilisateur. 
On essaie de se log avec `ssh zaz@<ip>` et le mot de passe trouvé. 

Ca fonctionne ! 🎉


