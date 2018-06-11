<result>{
    for $p in distinct-values(doc("j_caesar.xml")//SPEECH[LINE]/SPEAKER)
    return
    <answer>
    <who>{$p}</who>
        {for $a in doc("j_caesar.xml")//ACT[SCENE/SPEECH[SPEAKER=$p]/LINE]
         return 
        <when>{$a/TITLE/text()}</when>
        }
    </answer>
}</result>

