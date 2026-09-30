# dev-env-install

Il primo passo per installare l'ambiente di lavoro Cato su un Mac. Apri il Terminale e incolla:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/dev-env-install/main/install.sh)"
```

Installa Homebrew e la CLI di GitHub, ti fa entrare con il tuo utente GitHub (si apre il browser) e
scarica il repo privato del dev-env. Da lì in poi decide lui cosa installare, in base ai permessi che
ti sono stati dati: non devi scegliere niente.

Se ti dice che il tuo utente non vede il repo, chiedi a chi ti ha invitato di aggiungerti al team
giusto e rilancia lo stesso comando: rifà solo quello che manca.

Questo repo è pubblico perché è il pezzo che serve **prima** di avere accesso a qualcosa. Per questo
contiene solo `install.sh`, che non porta segreti né nomi di sistemi interni.
