/**
 * Licensed to Cloudera, Inc. under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  Cloudera, Inc. licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *  
 * http://www.apache.org/licenses/LICENSE-2.0
 *  
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.cloudera.whirr.kerberos;

import static org.apache.whirr.RolePredicates.role;
import static org.jclouds.scriptbuilder.domain.Statements.call;

import java.io.IOException;
import java.util.NoSuchElementException;

import org.apache.commons.configuration.Configuration;
import org.apache.whirr.ClusterSpec;
import org.apache.whirr.service.ClusterActionEvent;
import org.apache.whirr.service.ClusterActionHandlerSupport;

public abstract class BaseHandler extends ClusterActionHandlerSupport {

	protected Configuration getConfiguration(ClusterSpec spec) throws IOException {
		return getConfiguration(spec, "whirr-kerberos-default.properties");
	}

	@Override
	protected void beforeBootstrap(ClusterActionEvent event) throws IOException {
		addStatement(event, call("configure_hostnames"));
		addStatement(event, call("install_kerberos_client"));
	}

	@Override
	protected void beforeConfigure(ClusterActionEvent event) throws IOException {
		try {
			addStatement(
			  event,
			  call("configure_kerberos_client", "-h", event.getCluster()
			    .getInstanceMatching(role(KerberosServerHandler.ROLE))
			    .getPublicHostName()));
		} catch (NoSuchElementException e) {
			addStatement(event, call("configure_kerberos_client", "-h", "localhost"));
		}
	}
}
