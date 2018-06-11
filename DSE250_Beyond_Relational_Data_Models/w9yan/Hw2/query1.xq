<result>{
    for $a in doc("j_caesar.xml")//ACT
    for $s in $a/SCENE/SPEECH[LINE='Et tu, Brute! Then fall, Caesar.']
    return 
    <answer>
    <who>{$s/SPEAKER/text()}</who>
    <when>{$a/TITLE/text()}</when>
    </answer>
}</result>


