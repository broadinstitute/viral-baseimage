version 1.0

task recursion {
  input {
    Int    n
    String self_uri="https://raw.githubusercontent.com/broadinstitute/viral-baseimage/dp-inception/dumbidea.wdl"
  }
  command <<<
    set -ex
    if [ ~{n} -gt 0 ]; then
      miniwdl run "~{self_uri}" n=~{n}
  python3 << CODE
  import json
  with open('_LAST/outputs.json', 'rt') as inf:
     outs = json.load(inf)
  outs['inception.out']["~{n}"] = "success"
  with open("OUT.json", "wt") as outf:
     json.dump(outs['inception.out'], outf)
  CODE
    else
      echo '{"0": "did_not_execute"}' > OUT.json
    fi
  >>>
  runtime {
    docker: "quay.io/broadinstitute/viral-baseimage:latest"
    cpu: 1
    memory: "1 GB"
  }
  output {
    Map[Int,String] out = read_json("OUT.json")
  }
}

workflow inception {

 input {
   Int  n
 }

 call recursion {
   input:
     n=n-1
 }

 output {
   Map[Int,String] out = recursion.out
 }
}
