<result>{
    for $p in doc("j_caesar.xml")//PERSONA
    where every $a in doc("j_caesar.xml")//ACT
    satisfies $a//SPEECH[SPEAKER=$p]/LINE
    return <character>{$p/text()}</character>
}</result>

