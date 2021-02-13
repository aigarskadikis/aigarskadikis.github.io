SELECT `userid` FROM `acknowledges` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `eventid` FROM `acknowledges` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `actionid` FROM `alerts` WHERE `actionid` NOT IN (SELECT `actionid` FROM `actions`);
SELECT `eventid` FROM `alerts` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `userid` FROM `alerts` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `mediatypeid` FROM `alerts` WHERE `mediatypeid` NOT IN (SELECT `mediatypeid` FROM `media_type`);
SELECT `p_eventid` FROM `alerts` WHERE `p_eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `acknowledgeid` FROM `alerts` WHERE `acknowledgeid` NOT IN (SELECT `acknowledgeid` FROM `acknowledges`);
SELECT `applicationid` FROM `application_discovery` WHERE `applicationid` NOT IN (SELECT `applicationid` FROM `applications`);
SELECT `application_prototypeid` FROM `application_discovery` WHERE `application_prototypeid` NOT IN (SELECT `application_prototypeid` FROM `application_prototype`);
SELECT `itemid` FROM `application_prototype` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `templateid` FROM `application_prototype` WHERE `templateid` NOT IN (SELECT `application_prototypeid` FROM `application_prototype`);
SELECT `applicationid` FROM `application_template` WHERE `applicationid` NOT IN (SELECT `applicationid` FROM `applications`);
SELECT `templateid` FROM `application_template` WHERE `templateid` NOT IN (SELECT `applicationid` FROM `applications`);
SELECT `hostid` FROM `applications` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `userid` FROM `auditlog` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `auditid` FROM `auditlog_details` WHERE `auditid` NOT IN (SELECT `auditid` FROM `auditlog`);
SELECT `proxy_hostid` FROM `autoreg_host` WHERE `proxy_hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `actionid` FROM `conditions` WHERE `actionid` NOT IN (SELECT `actionid` FROM `actions`);
SELECT `correlationid` FROM `corr_condition` WHERE `correlationid` NOT IN (SELECT `correlationid` FROM `correlation`);
SELECT `corr_conditionid` FROM `corr_condition_group` WHERE `corr_conditionid` NOT IN (SELECT `corr_conditionid` FROM `corr_condition`);
SELECT `corr_conditionid` FROM `corr_condition_tag` WHERE `corr_conditionid` NOT IN (SELECT `corr_conditionid` FROM `corr_condition`);
SELECT `corr_conditionid` FROM `corr_condition_tagpair` WHERE `corr_conditionid` NOT IN (SELECT `corr_conditionid` FROM `corr_condition`);
SELECT `corr_conditionid` FROM `corr_condition_tagvalue` WHERE `corr_conditionid` NOT IN (SELECT `corr_conditionid` FROM `corr_condition`);
SELECT `correlationid` FROM `corr_operation` WHERE `correlationid` NOT IN (SELECT `correlationid` FROM `correlation`);
SELECT `dashboardid` FROM `dashboard_user` WHERE `dashboardid` NOT IN (SELECT `dashboardid` FROM `dashboard`);
SELECT `userid` FROM `dashboard_user` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `dashboardid` FROM `dashboard_usrgrp` WHERE `dashboardid` NOT IN (SELECT `dashboardid` FROM `dashboard`);
SELECT `usrgrpid` FROM `dashboard_usrgrp` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `druleid` FROM `dchecks` WHERE `druleid` NOT IN (SELECT `druleid` FROM `drules`);
SELECT `druleid` FROM `dhosts` WHERE `druleid` NOT IN (SELECT `druleid` FROM `drules`);
SELECT `dhostid` FROM `dservices` WHERE `dhostid` NOT IN (SELECT `dhostid` FROM `dhosts`);
SELECT `dcheckid` FROM `dservices` WHERE `dcheckid` NOT IN (SELECT `dcheckid` FROM `dchecks`);
SELECT `eventid` FROM `event_recovery` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `r_eventid` FROM `event_recovery` WHERE `r_eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `c_eventid` FROM `event_recovery` WHERE `c_eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `eventid` FROM `event_suppress` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `maintenanceid` FROM `event_suppress` WHERE `maintenanceid` NOT IN (SELECT `maintenanceid` FROM `maintenances`);
SELECT `eventid` FROM `event_tag` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `regexpid` FROM `expressions` WHERE `regexpid` NOT IN (SELECT `regexpid` FROM `regexps`);
SELECT `itemid` FROM `functions` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `triggerid` FROM `functions` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `graphid` FROM `graph_discovery` WHERE `graphid` NOT IN (SELECT `graphid` FROM `graphs`);
SELECT `templateid` FROM `graphs` WHERE `templateid` NOT IN (SELECT `graphid` FROM `graphs`);
SELECT `graphid` FROM `graphs_items` WHERE `graphid` NOT IN (SELECT `graphid` FROM `graphs`);
SELECT `itemid` FROM `graphs_items` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `groupid` FROM `group_discovery` WHERE `groupid` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `hostid` FROM `group_prototype` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `templateid` FROM `group_prototype` WHERE `templateid` NOT IN (SELECT `group_prototypeid` FROM `group_prototype`);
SELECT `hostid` FROM `host_discovery` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `hostid` FROM `host_inventory` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `hostid` FROM `hostmacro` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `templateid` FROM `hosts` WHERE `templateid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `hostid` FROM `hosts_groups` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `groupid` FROM `hosts_groups` WHERE `groupid` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `hostid` FROM `hosts_templates` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `templateid` FROM `hosts_templates` WHERE `templateid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `httptestid` FROM `httpstep` WHERE `httptestid` NOT IN (SELECT `httptestid` FROM `httptest`);
SELECT `httpstepid` FROM `httpstep_field` WHERE `httpstepid` NOT IN (SELECT `httpstepid` FROM `httpstep`);
SELECT `httpstepid` FROM `httpstepitem` WHERE `httpstepid` NOT IN (SELECT `httpstepid` FROM `httpstep`);
SELECT `itemid` FROM `httpstepitem` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `hostid` FROM `httptest` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `templateid` FROM `httptest` WHERE `templateid` NOT IN (SELECT `httptestid` FROM `httptest`);
SELECT `httptestid` FROM `httptest_field` WHERE `httptestid` NOT IN (SELECT `httptestid` FROM `httptest`);
SELECT `httptestid` FROM `httptestitem` WHERE `httptestid` NOT IN (SELECT `httptestid` FROM `httptest`);
SELECT `itemid` FROM `httptestitem` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `iconmapid` FROM `icon_mapping` WHERE `iconmapid` NOT IN (SELECT `iconmapid` FROM `icon_map`);
SELECT `hostid` FROM `interface` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `interfaceid` FROM `interface_discovery` WHERE `interfaceid` NOT IN (SELECT `interfaceid` FROM `interface`);
SELECT `parent_interfaceid` FROM `interface_discovery` WHERE `parent_interfaceid` NOT IN (SELECT `interfaceid` FROM `interface`);
SELECT `application_prototypeid` FROM `item_application_prototype` WHERE `application_prototypeid` NOT IN (SELECT `application_prototypeid` FROM `application_prototype`);
SELECT `itemid` FROM `item_application_prototype` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `itemid` FROM `item_condition` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `itemid` FROM `item_discovery` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `parent_itemid` FROM `item_discovery` WHERE `parent_itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `itemid` FROM `item_preproc` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `hostid` FROM `items` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `templateid` FROM `items` WHERE `templateid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `master_itemid` FROM `items` WHERE `master_itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `applicationid` FROM `items_applications` WHERE `applicationid` NOT IN (SELECT `applicationid` FROM `applications`);
SELECT `itemid` FROM `items_applications` WHERE `itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `maintenanceid` FROM `maintenance_tag` WHERE `maintenanceid` NOT IN (SELECT `maintenanceid` FROM `maintenances`);
SELECT `maintenanceid` FROM `maintenances_groups` WHERE `maintenanceid` NOT IN (SELECT `maintenanceid` FROM `maintenances`);
SELECT `groupid` FROM `maintenances_groups` WHERE `groupid` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `maintenanceid` FROM `maintenances_hosts` WHERE `maintenanceid` NOT IN (SELECT `maintenanceid` FROM `maintenances`);
SELECT `hostid` FROM `maintenances_hosts` WHERE `hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `maintenanceid` FROM `maintenances_windows` WHERE `maintenanceid` NOT IN (SELECT `maintenanceid` FROM `maintenances`);
SELECT `timeperiodid` FROM `maintenances_windows` WHERE `timeperiodid` NOT IN (SELECT `timeperiodid` FROM `timeperiods`);
SELECT `valuemapid` FROM `mappings` WHERE `valuemapid` NOT IN (SELECT `valuemapid` FROM `valuemaps`);
SELECT `userid` FROM `media` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `mediatypeid` FROM `media` WHERE `mediatypeid` NOT IN (SELECT `mediatypeid` FROM `media_type`);
SELECT `operationid` FROM `opcommand` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opcommand_grp` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opcommand_hst` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opconditions` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `actionid` FROM `operations` WHERE `actionid` NOT IN (SELECT `actionid` FROM `actions`);
SELECT `operationid` FROM `opgroup` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opinventory` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opmessage` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opmessage_grp` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `opmessage_usr` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `operationid` FROM `optemplate` WHERE `operationid` NOT IN (SELECT `operationid` FROM `operations`);
SELECT `eventid` FROM `problem` WHERE `eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `r_eventid` FROM `problem` WHERE `r_eventid` NOT IN (SELECT `eventid` FROM `events`);
SELECT `eventid` FROM `problem_tag` WHERE `eventid` NOT IN (SELECT `eventid` FROM `problem`);
SELECT `userid` FROM `profiles` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `groupid` FROM `rights` WHERE `groupid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `id` FROM `rights` WHERE `id` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `screenid` FROM `screen_user` WHERE `screenid` NOT IN (SELECT `screenid` FROM `screens`);
SELECT `userid` FROM `screen_user` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `screenid` FROM `screen_usrgrp` WHERE `screenid` NOT IN (SELECT `screenid` FROM `screens`);
SELECT `usrgrpid` FROM `screen_usrgrp` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `templateid` FROM `screens` WHERE `templateid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `screenid` FROM `screens_items` WHERE `screenid` NOT IN (SELECT `screenid` FROM `screens`);
SELECT `serviceid` FROM `service_alarms` WHERE `serviceid` NOT IN (SELECT `serviceid` FROM `services`);
SELECT `triggerid` FROM `services` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `serviceupid` FROM `services_links` WHERE `serviceupid` NOT IN (SELECT `serviceid` FROM `services`);
SELECT `servicedownid` FROM `services_links` WHERE `servicedownid` NOT IN (SELECT `serviceid` FROM `services`);
SELECT `serviceid` FROM `services_times` WHERE `serviceid` NOT IN (SELECT `serviceid` FROM `services`);
SELECT `userid` FROM `sessions` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `slideshowid` FROM `slides` WHERE `slideshowid` NOT IN (SELECT `slideshowid` FROM `slideshows`);
SELECT `screenid` FROM `slides` WHERE `screenid` NOT IN (SELECT `screenid` FROM `screens`);
SELECT `slideshowid` FROM `slideshow_user` WHERE `slideshowid` NOT IN (SELECT `slideshowid` FROM `slideshows`);
SELECT `userid` FROM `slideshow_user` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `slideshowid` FROM `slideshow_usrgrp` WHERE `slideshowid` NOT IN (SELECT `slideshowid` FROM `slideshows`);
SELECT `usrgrpid` FROM `slideshow_usrgrp` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `selementid` FROM `sysmap_element_trigger` WHERE `selementid` NOT IN (SELECT `selementid` FROM `sysmaps_elements`);
SELECT `triggerid` FROM `sysmap_element_trigger` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `selementid` FROM `sysmap_element_url` WHERE `selementid` NOT IN (SELECT `selementid` FROM `sysmaps_elements`);
SELECT `sysmapid` FROM `sysmap_shape` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `sysmapid` FROM `sysmap_url` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `sysmapid` FROM `sysmap_user` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `userid` FROM `sysmap_user` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `sysmapid` FROM `sysmap_usrgrp` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `usrgrpid` FROM `sysmap_usrgrp` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `sysmapid` FROM `sysmaps_elements` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `linkid` FROM `sysmaps_link_triggers` WHERE `linkid` NOT IN (SELECT `linkid` FROM `sysmaps_links`);
SELECT `triggerid` FROM `sysmaps_link_triggers` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `sysmapid` FROM `sysmaps_links` WHERE `sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
SELECT `selementid1` FROM `sysmaps_links` WHERE `selementid1` NOT IN (SELECT `selementid` FROM `sysmaps_elements`);
SELECT `selementid2` FROM `sysmaps_links` WHERE `selementid2` NOT IN (SELECT `selementid` FROM `sysmaps_elements`);
SELECT `usrgrpid` FROM `tag_filter` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `groupid` FROM `tag_filter` WHERE `groupid` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `proxy_hostid` FROM `task` WHERE `proxy_hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `taskid` FROM `task_acknowledge` WHERE `taskid` NOT IN (SELECT `taskid` FROM `task`);
SELECT `taskid` FROM `task_check_now` WHERE `taskid` NOT IN (SELECT `taskid` FROM `task`);
SELECT `taskid` FROM `task_close_problem` WHERE `taskid` NOT IN (SELECT `taskid` FROM `task`);
SELECT `taskid` FROM `task_remote_command` WHERE `taskid` NOT IN (SELECT `taskid` FROM `task`);
SELECT `taskid` FROM `task_remote_command_result` WHERE `taskid` NOT IN (SELECT `taskid` FROM `task`);
SELECT `triggerid_down` FROM `trigger_depends` WHERE `triggerid_down` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `triggerid_up` FROM `trigger_depends` WHERE `triggerid_up` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `triggerid` FROM `trigger_discovery` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `triggerid` FROM `trigger_tag` WHERE `triggerid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `templateid` FROM `triggers` WHERE `templateid` NOT IN (SELECT `triggerid` FROM `triggers`);
SELECT `usrgrpid` FROM `users_groups` WHERE `usrgrpid` NOT IN (SELECT `usrgrpid` FROM `usrgrp`);
SELECT `userid` FROM `users_groups` WHERE `userid` NOT IN (SELECT `userid` FROM `users`);
SELECT `dashboardid` FROM `widget` WHERE `dashboardid` NOT IN (SELECT `dashboardid` FROM `dashboard`);
SELECT `widgetid` FROM `widget_field` WHERE `widgetid` NOT IN (SELECT `widgetid` FROM `widget`);
SELECT `value_groupid` FROM `widget_field` WHERE `value_groupid` NOT IN (SELECT `groupid` FROM `hstgrp`);
SELECT `value_hostid` FROM `widget_field` WHERE `value_hostid` NOT IN (SELECT `hostid` FROM `hosts`);
SELECT `value_itemid` FROM `widget_field` WHERE `value_itemid` NOT IN (SELECT `itemid` FROM `items`);
SELECT `value_graphid` FROM `widget_field` WHERE `value_graphid` NOT IN (SELECT `graphid` FROM `graphs`);
SELECT `value_sysmapid` FROM `widget_field` WHERE `value_sysmapid` NOT IN (SELECT `sysmapid` FROM `sysmaps`);
