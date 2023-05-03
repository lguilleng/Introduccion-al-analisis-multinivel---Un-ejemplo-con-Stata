/* Introducción al análisis multinivel */

use escuelas, clear
describe

* Explorar el comportamiento del puntaje individual y promedio por escuela

bysort escuela: egen y_mean=mean(y)
twoway scatter y escuela, msize(tiny) || connected y_mean escuela, connect(L) clwidth(thick) clcolor(black) mcolor(black) msymbol(none) || , ytitle(y)

* ¿Cómo se comportan los puntajes en función a la condición de ser femenino?

quietly statsby inter=_b[_cons] slope=_b[x1], by(escuela) /*
*/ saving(ols, replace): regress y x1
quietly sort escuela
quietly merge escuela using ols
quietly drop _merge
quietly gen yhat_ols= inter + slope*x1
quietly sort escuela x1
quietly separate y, by(escuela)
quietly separate yhat_ols, by(escuela)
twoway connected yhat_ols1-yhat_ols65 x1 || lfit y x1, clwidth(thick) /*
 */ clcolor(black) legend(off) ytitle(y)

/* Los siguientes comandos se añaden para eliminar las variables y archivo creado,    con la finalidad de que si se ejecuta nuevamente los comandos anteriores,
   no de error. */

drop inter-yhat_ols65quietly erase ols.dta

* Modelo con intercepto variable

xtmixed y || escuela: , mle nolog

* Modelo con intercepto variable (un nivel, un predictor)

xtmixed y x1 || escuela: , mle nolog

* Modelo con intercepto y coeficiente variable

xtmixed y x1 || escuela: x1, mle nolog covariance(unstructure)

* Modelo con pendiente variable

xtmixed y x1 || _all: R.x1, mle nolog


/* Post estimación */

* Ajuste de interceptos aleatorios y guardando resultados 
 
  quietly xtmixed y x1 || escuela:, mle nolog
  estimates store ri

* Ajuste de coeficientes aleatorios y guardando resultados #

  quietly xtmixed y x1 || escuela: x1, mle nolog covariance(unstructure)
  estimates store rc

​* Ejecutando prueba de likelihood-ratio test para comparar #

  lrtest ri rc

/* La siguiente línea es solo para eliminar las variables que genera el
   comando   estimates, con la finalidad de poder repetir los comandos
   y no de error */

   drop _est_ri _est_rc

/* Estimar los efectos aleatorios */

   quietly quietly xtmixed y x1 || escuela: x1, mle nolog /*
     */ covariance(unstructure) variance
   predict u*, reffects
   bysort escuela: generate grupo=(_n==1)
   list escuela u2 u1 if escuela<=10 & grupo

/* Calcular las intercepciones y pendientes para cada escuela */

   gen intercepto= _b[_cons] + u2
   gen pendiente = _b[x1] + u1
   list escuela intercepto pendiente if escuela<=10 & grupo

/* Estimar los puntajes en base a los modelos estimados para cada escuela */

   predict yhat_fit, fitted

/* Graficando los modelos estimados para cada escuela */

   twoway connected yhat_fit x1 if escuela<=10, connect(L)

/* Residuos en base al modelo estimado */

   predict residuos, residuals
   predict resid_std, rstandard

/* Revisión rápida de los residuos */

   qnorm resid_std

