// Veille : recherche et filtre par thème.
// Sans JavaScript, la page reste une liste complète rangée par thème ;
// ce script affiche la recherche et les filtres, puis masque les fiches
// qui ne correspondent pas.
(function () {
  "use strict";

  var racine = document.querySelector(".veille");
  if (!racine) return;
  var outils = racine.querySelector(".veille-outils");
  var champ = racine.querySelector("#veille-recherche");
  var statut = racine.querySelector("#veille-statut");
  if (!outils || !champ || !statut) return;

  var boutons = Array.prototype.slice.call(racine.querySelectorAll(".veille-filtre"));
  var fiches = Array.prototype.slice.call(racine.querySelectorAll(".veille-lien"));
  var sections = Array.prototype.slice.call(racine.querySelectorAll(".veille-theme"));
  var total = fiches.length;
  var theme = "tous";

  // Recherche sans tenir compte des accents ni de la casse.
  function normaliser(texte) {
    return texte.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  }

  // Texte cherché dans chaque fiche : titre, site, type, résumé, pourquoi, mots-clés.
  var CHAMPS = ".veille-titre-texte, .veille-domaine, .veille-type, .veille-resume, .veille-pourquoi, .veille-mot";
  fiches.forEach(function (fiche) {
    var morceaux = Array.prototype.map.call(fiche.querySelectorAll(CHAMPS), function (e) {
      return e.textContent;
    });
    fiche.dataset.texte = normaliser(morceaux.join(" "));
  });

  function appliquer() {
    var mots = normaliser(champ.value).split(/\s+/).filter(Boolean);
    var affiches = 0;
    fiches.forEach(function (fiche) {
      var visible = (theme === "tous" || fiche.dataset.theme === theme) &&
        mots.every(function (mot) { return fiche.dataset.texte.indexOf(mot) !== -1; });
      fiche.hidden = !visible;
      if (visible) affiches += 1;
    });
    sections.forEach(function (section) {
      section.hidden = !section.querySelector(".veille-lien:not([hidden])");
    });
    var filtre = mots.length > 0 || theme !== "tous";
    if (!filtre) {
      statut.textContent = "";
    } else if (affiches === 0) {
      statut.textContent = "Aucun lien ne correspond.";
    } else {
      statut.textContent = affiches + (affiches > 1 ? " liens" : " lien") + " sur " + total + ".";
    }
    racine.classList.toggle("veille-filtree", filtre);
  }

  boutons.forEach(function (bouton) {
    bouton.addEventListener("click", function () {
      theme = bouton.dataset.theme;
      boutons.forEach(function (b) { b.setAttribute("aria-pressed", String(b === bouton)); });
      appliquer();
    });
  });

  champ.addEventListener("input", appliquer);
  champ.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && champ.value) {
      champ.value = "";
      appliquer();
    }
  });

  outils.hidden = false;
  racine.classList.add("veille-active");
})();
