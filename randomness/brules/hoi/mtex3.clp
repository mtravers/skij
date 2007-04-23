<emptyLabel> f(?x) <- ((f1(x()) AND f2(y())) OR (f3(x()) OR f4(y()))) AND f5(w()).
<emptyLabel> good(?x) <- stupid(x()) OR (FNEG rich(?x)).
<emptyLabel> good(?x) <- (stupid(x) AND (FNEG rich(?x))) OR goodluck() OR god().
<emptyLabel> good(?x) <- (stupid(x) OR (FNEG rich(?x))) AND (goodluck() AND badluck()).
<emptyLabel> A() AND B() AND (CNEG C()) <- (((a() OR b()) OR (c() AND d())) AND (e() OR f())) OR h().
<emptyLabel> CNEG fff(?x) <- ffg(x()).
<emptyLabel> f(x(), y()) <-.
<emptyLabel> f(x(), ?y) <-.
<emptyLabel> g(x(), ?y) <-.
<emptyLabel> large(x(), ?y) <- heavy().
<emptyLabel> medium(?x) <- size(larger(?x, ?f), heavier(?x, ?f)).
<emptyLabel> small(e(), ?f) <- light().
<lab1> bull(123()) <- pig(?y).
<23> bird(?x) <- fly(?x).
<emptyLabel> respectful(?x) <- education(degree(school(?m, USA()), major(?s, ?y))) AND wealth(networth(stock(?shares, ?company), bond(?yield, ?amount), ?cash)).
<emptyLabel> good(?x) <- tall(?x) AND big(?y) AND 123().
<emptyLabel> CNEG good(?x) <- stupid(x()) AND (FNEG rich(?x)).
<emptyLabel> CNEG bad(?y, x()) <- smart(?x) AND (CNEG rich(?x)).
<lab1> bull(123()) <- pig(?y).
<23> bird(?x) <- fly(?x).
<emptyLabel> good(?x) <- tall(?x) AND big(?y) AND 123().
<emptyLabel> CNEG good(?x) <- stupid(x()) AND (FNEG rich(?x)).
<emptyLabel> CNEG bad(?y, x()) <- smart(?x) AND (CNEG rich(?x)).
MUTEX_HEAD <- ff1(x()) AND gg(y(), ftt1(xx(), 3()), ftt2(a(), ?b)).
