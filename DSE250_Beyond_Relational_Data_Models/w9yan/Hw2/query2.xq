<speakers>{
    for $p in distinct-values(doc("j_caesar.xml")//SPEECH[LINE]/SPEAKER)
    return <character>{$p}</character>
}</speakers>

