# == Class: pe_metrics_dashboard::telegraf: (
#    Boolean $configure_telegraf - Add the telegraf config file
#)
#
class pe_metrics_dashboard::telegraf (
  Boolean $configure_telegraf         =  $pe_metrics_dashboard::params::configure_telegraf,
  String $influx_db_service_name      =  $pe_metrics_dashboard::params::influx_db_service_name,
  Array[String] $additional_metrics   = [],
  ) {

  # Stolen from https://github.com/npwalker/pe_metric_curl_cron_jobs/blob/master/manifests/puppetdb.pp
  # Configure the mbean metrics to be collected
  $activemq_metrics = [
  { 'name' => 'amq_metrics',
    'url'  => 'org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=puppetlabs.puppetdb.commands' },
  ]

  $base_metrics = [
    { 'name' => 'global_command-parse-time',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.command-parse-time' },
    { 'name' => 'global_discarded',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.discarded' },
    { 'name' => 'global_fatal',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.fatal' },
    { 'name' => 'global_generate-retry-message-time',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.generate-retry-message-time' },
    { 'name' => 'global_message-persistence-time',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.message-persistence-time' },
    { 'name' => 'global_retried',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.retried' },
    { 'name' => 'global_retry-counts',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.retry-counts' },
    { 'name' => 'global_retry-persistence-time',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.retry-persistence-time' },
    { 'name' => 'global_seen',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.seen' },
    { 'name' => 'global_processed',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.processed' },
    { 'name' => 'global_processing-time',
      'url'  => 'puppetlabs.puppetdb.mq:name=global.processing-time' },
  ]

  $storage_metrics = [
    { 'name' => 'storage_add-edges',
      'url'  => 'puppetlabs.puppetdb.storage:name=add-edges' },
    { 'name' => 'storage_add-resources',
      'url'  => 'puppetlabs.puppetdb.storage:name=add-resources' },
    { 'name' => 'storage_catalog-hash',
      'url'  => 'puppetlabs.puppetdb.storage:name=catalog-hash' },
    { 'name' => 'storage_catalog-hash-match-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=catalog-hash-match-time' },
    { 'name' => 'storage_catalog-hash-miss-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=catalog-hash-miss-time' },
    { 'name' => 'storage_gc-catalogs-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-catalogs-time' },
    { 'name' => 'storage_gc-environments-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-environments-time' },
    { 'name' => 'storage_gc-fact-paths',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-fact-paths' },
    { 'name' => 'storage_gc-params-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-params-time' },
    { 'name' => 'storage_gc-report-statuses',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-report-statuses' },
    { 'name' => 'storage_gc-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=gc-time' },
    { 'name' => 'storage_new-catalog-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=new-catalog-time' },
    { 'name' => 'storage_new-catalogs',
      'url'  => 'puppetlabs.puppetdb.storage:name=new-catalogs' },
    { 'name' => 'storage_replace-catalog-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=replace-catalog-time' },
    { 'name' => 'storage_replace-facts-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=replace-facts-time' },
    { 'name' => 'storage_resource-hashes',
      'url'  => 'puppetlabs.puppetdb.storage:name=resource-hashes' },
    { 'name' => 'storage_store-report-time',
      'url'  => 'puppetlabs.puppetdb.storage:name=store-report-time' },
  ]

  #TODO: Track these on a less frequent cadence because they are slow to run
  $storage_metrics_db_queries = [
    { 'name' => 'storage_catalog-volitilty',
      'url'  => 'puppetlabs.puppetdb.storage:name=catalog-volitilty' },
    { 'name' => 'storage_duplicate-catalogs',
      'url'  => 'puppetlabs.puppetdb.storage:name=duplicate-catalogs' },
    { 'name' => 'storage_duplicate-pct',
      'url'  => 'puppetlabs.puppetdb.storage:name=duplicate-pct' },
  ]

  $numbers = $::pe_server_version ? {
    /^2015.2/     => {'catalogs' => 6, 'facts' => 4, 'reports' => 6},
    /^2015.3/     => {'catalogs' => 7, 'facts' => 4, 'reports' => 6},
    /^2016.(1|2)/ => {'catalogs' => 8, 'facts' => 4, 'reports' => 7},
    /^2016.(4|5)/ => {'catalogs' => 9, 'facts' => 5, 'reports' => 8},
    /^2017.(1|2)/ => {'catalogs' => 9, 'facts' => 5, 'reports' => 8},
    default       => {'catalogs' => 9, 'facts' => 5, 'reports' => 8},
  }

  $version_specific_metrics = [
    { 'name' => 'mq_replace_catalog_retried',
      'url'  => "puppetlabs.puppetdb.mq:name=replace catalog.${numbers['catalogs']}.retried" },
    { 'name' => 'mq_replace_catalog_retry-counts',
      'url'  => "puppetlabs.puppetdb.mq:name=replace catalog.${numbers['catalogs']}.retry-counts" },
    { 'name' => 'mq_replace_facts_retried',
      'url'  => "puppetlabs.puppetdb.mq:name=replace facts.${numbers['facts']}.retried" },
    { 'name' => 'mq_replace_facts_retry-counts',
      'url'  => "puppetlabs.puppetdb.mq:name=replace facts.${numbers['facts']}.retry-counts" },
    { 'name' => 'mq_store_report_retried',
      'url'  => "puppetlabs.puppetdb.mq:name=store report.${numbers['reports']}.retried" },
    { 'name' => 'mq_store_reports_retry-counts',
      'url'  => "puppetlabs.puppetdb.mq:name=store report.${numbers['reports']}.retry-counts" },
  ]

  $connection_pool_metrics = [
    { 'name' => 'PDBReadPool_pool_ActiveConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.ActiveConnections' },
    { 'name' => 'PDBReadPool_pool_IdleConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.IdleConnections' },
    { 'name' => 'PDBReadPool_pool_PendingConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.PendingConnections' },
    { 'name' => 'PDBReadPool_pool_TotalConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.TotalConnections' },
    { 'name' => 'PDBReadPool_pool_Usage',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.Usage' },
    { 'name' => 'PDBReadPool_pool_Wait',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBReadPool.pool.Wait' },
    { 'name' => 'PDBWritePool_pool_ActiveConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.ActiveConnections' },
    { 'name' => 'PDBWritePool_pool_IdleConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.IdleConnections' },
    { 'name' => 'PDBWritePool_pool_PendingConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.PendingConnections' },
    { 'name' => 'PDBWritePool_pool_TotalConnections',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.TotalConnections' },
    { 'name' => 'PDBWritePool_pool_Usage',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.Usage' },
    { 'name' => 'PDBWritePool_pool_Wait',
      'url'  => 'puppetlabs.puppetdb.database:name=PDBWritePool.pool.Wait' },
  ]

  $puppetdb_metrics = $::pe_server_version ? {
    /^2015./ => $activemq_metrics,
    /^2016./ => $activemq_metrics + $base_metrics + $storage_metrics + $connection_pool_metrics + $version_specific_metrics,
    default  => $base_metrics + $storage_metrics + $connection_pool_metrics + $version_specific_metrics,
  }

  package { 'telegraf':
    ensure  => present,
    require => Class['pe_metrics_dashboard::repos'],
  }

  service { 'telegraf':
    ensure  => running,
    enable  => true,
    require => [Package['telegraf'], Service[$influx_db_service_name]],
  }

  if $configure_telegraf {

    file {'/etc/telegraf/telegraf.conf':
      ensure  => file,
      owner   => 0,
      group   => 0,
      content => epp('pe_metrics_dashboard/telegraf.conf.epp',
        {puppetdb_metrics => $puppetdb_metrics}),
      notify  => Service['telegraf'],
      require => Package['telegraf'],
    }
  }
}
