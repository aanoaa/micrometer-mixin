local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local singlestat = grafana.singlestat;

{
  _config+:: {
  },

  grafanaDashboards+:: {
    'micrometer.json':
      local availability30d =
        singlestat.new(
          '가용성(Availability) (%dd) > %.3f%%' % [$._config.SLOs.days, 100 * $._config.SLOs.target],
          datasource='$datasource',
          span=4,
          format='percentunit',
          decimals=3,
          description='%d일 동안 성공적이고 신속하게 응답한 요청(read+write)은 몇 퍼센트입니까?' % $._config.SLOs.days,
        )
        .addTarget(prometheus.target('1 - (sum (status:micrometer_request_total:increase%dd{status=~"5..",application="$application"} or vector(0))) / sum (status:micrometer_request_total:increase%dd{application="$application"})' % [$._config.SLOs.days, $._config.SLOs.days]));

      local readAvailability =
        singlestat.new(
          '가용성(read) (%dd)' % $._config.SLOs.days,
          datasource='$datasource',
          span=4,
          format='percentunit',
          decimals=3,
          description='%d일 동안 성공적이고 신속하게 응답한 요청(GET)은 몇 퍼센트입니까?' % $._config.SLOs.days,
        )
        .addTarget(prometheus.target('1 - (sum (status:micrometer_request_total:increase%dd{verb="read",status=~"5..",application="$application"} or vector(0))) / sum (status:micrometer_request_total:increase%dd{verb="read",application="$application"})' % [$._config.SLOs.days, $._config.SLOs.days]));

      local readRequests =
        graphPanel.new(
          '읽기 APIs - 요청 수',
          datasource='$datasource',
          span=4,
          format='reqps',
          stack=true,
          fill=10,
          description='read requests (GET) per second by status code',
        )
        .addSeriesOverride({ alias: '/2../i', color: '#56A64B' })
        .addSeriesOverride({ alias: '/3../i', color: '#F2CC0C' })
        .addSeriesOverride({ alias: '/4../i', color: '#3274D9' })
        .addSeriesOverride({ alias: '/5../i', color: '#E02F44' })
        .addTarget(prometheus.target('sum by (status) (status:micrometer_request_total:rate5m{verb="read",application="$application"})' % $._config, legendFormat='{{ status }}'));

      local readErrors =
        graphPanel.new(
          '읽기 APIs - 오류 수',
          datasource='$datasource',
          min=0,
          span=4,
          format='reqps',
          description='read requests (GET) per second by (5xx) error code',
        )
        .addTarget(prometheus.target('sum by (uri) (status:micrometer_request_total:rate5m{verb="read",status=~"5..",application="$application"})' % $._config, legendFormat='{{ resource }}'));

      local readDuration =
        graphPanel.new(
          '읽기 APIs - 응답시간',
          datasource='$datasource',
          span=4,
          format='s',
          description='지정된 리소스의 읽기(GET)에 대한 응답시간',
        )
        .addTarget(prometheus.target('sum by (uri) (rate(http_server_requests_seconds_sum{application="$application",status!~"5..",method=~"GET"}[5m])) / sum by (uri) (rate(http_server_requests_seconds_count{application="$application",status!~"5..",method=~"GET"}[5m])) > 0' % $._config, legendFormat='{{ url }}'));

      local writeAvailability =
        singlestat.new(
          '가용성(write) (%dd)' % $._config.SLOs.days,
          datasource='$datasource',
          span=4,
          format='percentunit',
          decimals=3,
          description='%d일 동안 성공적이고 신속하게 응답한 요청(POST|PUT|PATCH|DELETE)은 몇 퍼센트입니까?' % $._config.SLOs.days,
        )
        .addTarget(prometheus.target('1 - (sum (status:micrometer_request_total:increase%dd{verb="write",status=~"5..",application="$application"} or vector(0))) / sum (status:micrometer_request_total:increase%dd{verb="write",application="$application"})' % [$._config.SLOs.days, $._config.SLOs.days]));

      local writeRequests =
        graphPanel.new(
          '쓰기 APIs - 요청 수',
          datasource='$datasource',
          span=4,
          format='reqps',
          stack=true,
          fill=10,
          description='write requests (POST|PUT|PATCH|DELETE) per second by status code',
        )
        .addSeriesOverride({ alias: '/2../i', color: '#56A64B' })
        .addSeriesOverride({ alias: '/3../i', color: '#F2CC0C' })
        .addSeriesOverride({ alias: '/4../i', color: '#3274D9' })
        .addSeriesOverride({ alias: '/5../i', color: '#E02F44' })
        .addTarget(prometheus.target('sum by (status) (status:micrometer_request_total:rate5m{verb="write",application="$application"})' % $._config, legendFormat='{{ status }}'));

      local writeErrors =
        graphPanel.new(
          '쓰기 APIs - 오류 수',
          datasource='$datasource',
          min=0,
          span=4,
          format='reqps',
          description='write requests (POST|PUT|PATCH|DELETE) per second by (5xx) error code',
        )
        .addTarget(prometheus.target('sum by (uri) (status:micrometer_request_total:rate5m{verb="write",status=~"5..",application="$application"})' % $._config, legendFormat='{{ resource }}'));

      local writeDuration =
        graphPanel.new(
          '쓰기 APIs - 응답시간',
          datasource='$datasource',
          span=4,
          format='s',
          description='지정된 리소스의 쓰기(POST|PUT|PATCH|DELETE)에 대한 응답시간',
        )
        .addTarget(prometheus.target('sum by (uri) (rate(http_server_requests_seconds_sum{application="$application",status!~"5..",method=~"POST|PUT|PATCH|DELETE"}[5m])) / sum by (uri) (rate(http_server_requests_seconds_count{application="$application",status!~"5..",method=~"POST|PUT|PATCH|DELETE"}[5m])) > 0' % $._config, legendFormat='{{ url }}'));

      dashboard.new(
        '%(dashboardNamePrefix)sSLOs 대시보드' % $._config,
        time_from='now-6h',
        tags=($._config.dashboardTags),
      ).addTemplate(
        {
          current: {
            text: $._config.datasourceName,
            value: $._config.datasourceName,
          },
          hide: 0,
          label: 'Data Source',
          name: 'datasource',
          options: [],
          query: 'prometheus',
          regex: $._config.datasourceFilterRegex,
          type: 'datasource',
        },
      )
      .addTemplate(
        template.new(
          'application',
          '$datasource',
          'label_values(http_server_requests_seconds_count, application)',
          label='Application',
          refresh='time',
          sort=1,
        )
      )
      .addPanel(
        grafana.text.new(
          title='Notice',
          content='micrometer 의 SLOs',
          span=12,
        ),
        gridPos={
          h: 2,
          w: 24,
          x: 0,
          y: 0,
        },
      )
      .addRow(
        row.new()
        .addPanel(availability30d)
        .addPanel(readAvailability)
        .addPanel(writeAvailability)
      )
      .addRow(
        row.new()
        .addPanel(readRequests)
        .addPanel(readErrors)
        .addPanel(readDuration)
      )
      .addRow(
        row.new()
        .addPanel(writeRequests)
        .addPanel(writeErrors)
        .addPanel(writeDuration)
      ),
  },
}
