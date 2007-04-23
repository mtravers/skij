<emptyLabel> CNEG f(?x) <- (((FNEG CNEG f1(x)) AND (FNEG CNEG f2(y))) OR ((FNEG CNEG f3(x)) OR (FNEG CNEG f4(y)))) AND (FNEG CNEG f5(w)).
<emptyLabel> CNEG good(?x) <- (FNEG CNEG stupid(x)) OR (FNEG CNEG rich(?x)).
<emptyLabel> CNEG good(?x) <- ((FNEG CNEG stupid("x")) AND (FNEG CNEG rich(?x))) OR (FNEG CNEG goodluck()) OR (FNEG CNEG god()).
<emptyLabel> CNEG good(?x) <- ((FNEG CNEG stupid("x")) OR (FNEG CNEG rich(?x))) AND ((FNEG CNEG goodluck()) AND (FNEG CNEG badluck())).
<emptyLabel> (CNEG A()) AND (CNEG B()) AND (CNEG C()) <- ((((FNEG CNEG a()) OR (FNEG CNEG b())) OR ((FNEG CNEG c()) AND (FNEG CNEG d()))) AND ((FNEG CNEG e()) OR (FNEG CNEG f()))) OR (FNEG CNEG h()).
<emptyLabel> CNEG fff(?x) <- FNEG CNEG ffg(x).
<emptyLabel> CNEG f(x, y) <-.
<emptyLabel> CNEG f(x, ?y) <-.
<emptyLabel> CNEG g(x, ?y) <-.
<emptyLabel> CNEG large(x, ?y) <- FNEG CNEG heavy().
<emptyLabel> CNEG medium(?x) <- FNEG CNEG size(larger, heavier).
<emptyLabel> CNEG small(e, ?f) <- FNEG CNEG light().
<lab1> CNEG bull(123) <- FNEG CNEG pig(?y).
<23> CNEG bird(?x) <- FNEG CNEG fly(?x).
<emptyLabel> CNEG respectful(?x) <- (FNEG CNEG education(degree)) AND (FNEG CNEG wealth(networth)).
<emptyLabel> CNEG good(?x) <- (FNEG CNEG tall(?x)) AND (FNEG CNEG big(?y)) AND (FNEG CNEG 123()).
<emptyLabel> CNEG good(?x) <- (FNEG CNEG stupid(x)) AND (FNEG CNEG rich(?x)).
<emptyLabel> CNEG bad(?y, x) <- (FNEG CNEG smart(?x)) AND (FNEG CNEG rich(?x)).
<lab1> CNEG bull(123) <- FNEG CNEG pig(?y).
<23> CNEG bird(?x) <- FNEG CNEG fly(?x).
<emptyLabel> CNEG good(?x) <- (FNEG CNEG tall(?x)) AND (FNEG CNEG big(?y)) AND (FNEG CNEG 123()).
<emptyLabel> CNEG good(?x) <- (FNEG CNEG stupid(x)) AND (FNEG CNEG rich(?x)).
<emptyLabel> CNEG bad(?y, x) <- (FNEG CNEG smart(?x)) AND (FNEG CNEG rich(?x)).
MUTEX_HEAD <- CNEG ff1(x) AND CNEG gg(y, ftt1, ftt2).
