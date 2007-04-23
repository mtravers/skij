
f(?x) <- ((f1(x) and f2(y)) or (f3(x) or f4(y))) and f5(w).

good(?x) <- stupid(x) or FNEG rich(?x).

good(?x) <- (stupid("x") and FNEG rich(?x)) or goodluck() or (god()).
good(?x) <- (stupid("x") or FNEG rich(?x)) and (goodluck() and badluck()).

A and B and CNEG C <- (((a or b) or (c and d)) and (e or f)) or h.

/*
this a comment
*/

cneg fff(?x) <- ffg(x).

f(x, y).

f(x, ?y) <-.
g(x, ?y) <-.

large(x, ?y) <- heavy.
medium(?x) <- size(larger(?x, ?f), heavier(?x, ?f)).
small(e, ?f) <- light().

<lab1>bull(123) <- pig(?y).
<23>  bird(?x) <- fly(?x).

respectful(?x) <- education(degree(school(?m,USA), major(?s, ?y))) and wealth(networth(stock(?shares, ?company), bond(?yield, ?amount), ?cash)).
good(?x) <- tall(?x) and big (?y) and 123.
CNEG good(?x) <- stupid(x) and FNEG rich(?x).
CNEG bad (?y, x) <- smart(?x) and CNEG rich(?x).

MUTEX_HEAD <- ff1(x) and gg(y, ftt1(xx, 3), ftt2(a, ?b)).

<lab1> bull(123) <- pig(?y).
<23>  bird(?x) <- fly(?x).

good(?x) <- tall(?x) and big (?y) and 123.
CNEG good(?x) <- stupid(x) and FNEG rich(?x).
CNEG bad (?y, x) <- smart(?x) and CNEG rich(?x).
