#!/bin/bash -p

if command -v mvn >/dev/null 2>&1; then
  mvn_cmd="mvn"
else
  mvn_cmd="./mvnw"
fi

mvn_version=$($mvn_cmd -v | grep 'Apache Maven' | awk '{print $3}')
if [[ "$mvn_version" == 4* ]]; then
  profiles='-P?coverage,?ci'
else
  profiles='-Pcoverage,ci'
fi

if [[ "$PWD" == *shiro* ]]; then
  mvn_opts="-pl :jakarta-ee-support"
else
  mvn_opts="-N"
fi

cmdline=$($mvn_cmd -ntp initialize help:evaluate $profiles \
-Dexpression=jacocoAgent -q -DforceStdout -DjacocoPort=14948 $mvn_opts \
-Djacoco.destFile=target/jacoco-it.exec \
-Dmaven.build.cache.enabled=false \
| groovy -e '
line = System.in.newReader().readLine()
def agent = (line =~ /(-javaagent.*)/)[0][1]
agent = (agent + '\'',output=tcpserver'\'').replaceAll(/[\/:=]/, /\\$0/).replaceAll(/[$]/, /\\$0/)
println "$agent"
')

asadmin create-jvm-options ${cmdline}
echo "Don't forget to restart the domain"