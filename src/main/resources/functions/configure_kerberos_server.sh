#
# Licensed to Cloudera, Inc. under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# Cloudera, Inc. licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -x

function configure_kerberos_server() {
  service krb5kdc stop
  service kadmin stop
  sed -i -e "s/EXAMPLE\.COM/CDHCLUSTER\.COM/" /var/kerberos/krb5kdc/kdc.conf
  yum install -y expect
  cat >> run_kdb5_util <<END
#!/usr/bin/expect -f
set timeout 5000
spawn sudo kdb5_util create -s
expect {Enter KDC database master key: } { send "admin\r" }
expect {Re-enter KDC database master key to verify: } { send "admin\r" }
expect EOF
END
  chmod +x run_kdb5_util
  ./run_kdb5_util
  rm -rf run_kdb5_util
  sed -i -e "s/EXAMPLE\.COM/CDHCLUSTER\.COM/" /var/kerberos/krb5kdc/kadm5.acl
  cat >> run_addpinc <<END
#!/usr/bin/expect -f
set timeout 5000
set principal_primary [lindex \$argv 0]
set principal_instance [lindex \$argv 1]
spawn sudo kadmin.local -q "addprinc \$principal_primary\$principal_instance@CDHCLUSTER.COM"
expect -re {Enter password for principal .*} { send "\$principal_primary\r" }
expect -re {Re-enter password for principal .* } { send "\$principal_primary\r" }
expect EOF
END
  chmod +x run_addpinc
  ./run_addpinc whirr /admin
  ./run_addpinc hdfs
  ./run_addpinc cdhuser
  rm -rf ./run_addpinc
  service krb5kdc start
  service kadmin start
  chkconfig krb5kdc on
  chkconfig kadmin on
  CONFIGURE_KERBEROS_DONE=1
}
