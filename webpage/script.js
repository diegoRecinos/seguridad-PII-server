// Resalta la ficha del currículum a la que lleva cada enlace "Ver currículum"
document.querySelectorAll('.ver-cv').forEach(function (enlace) {
  enlace.addEventListener('click', function () {
    var destino = document.getElementById(enlace.dataset.cv);
    if (!destino) return;

    document.querySelectorAll('.tarjeta-cv.resaltada').forEach(function (t) {
      t.classList.remove('resaltada');
    });

    destino.classList.add('resaltada');
    setTimeout(function () {
      destino.classList.remove('resaltada');
    }, 2500);
  });
});

// Año actual en el pie de página
var anio = document.getElementById('anio');
if (anio) anio.textContent = new Date().getFullYear();
