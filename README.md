# Gite da Milano · Ferrate

Le vie ferrate raggiungibili entro 3 ore d'auto da Milano, con schede tecniche, stato aperta/chiusa aggiornato ogni giorno e previsioni meteo a 7 giorni dal confronto di sei modelli, calcolate alla quota di ogni ferrata.

## Come funziona

- `index.html`: l'interfaccia, fatta di HTML, CSS e JavaScript senza fasi di compilazione.
- `data/ferrate.js`: il dataset delle 193 ferrate (dati tecnici da ferrate365.it, ferrate estere da OpenStreetMap, SAC e graubuenden.ch, tempi d'auto calcolati con OSRM).
- `data/stato.js`: lo stato aperta/chiusa, rigenerato ogni giorno da `scripts/aggiorna-stato.ps1` tramite GitHub Actions.
- `assets/style.src.css`: il sorgente dello stile. Dopo una modifica si rigenera `assets/style.css` con `py scripts/build-css.py`.
- Il meteo viene scaricato direttamente dal browser da [Open-Meteo](https://open-meteo.com) (CC BY 4.0).

## Pubblicazione

Il sito è servito da GitHub Pages. Il workflow `.github/workflows/pages.yml`:
- pubblica il sito a ogni push su `main`;
- ogni mattina aggiorna `data/stato.js` e ripubblica il sito.

Prima di partire verifica sempre stato del percorso, bollettini ufficiali e condizioni.
