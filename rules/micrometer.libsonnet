{
  _config+:: {
    readSelector: 'method="GET"',
    writeSelector: 'method=~"POST|PUT|PATCH|DELETE"',

    readLatency: '1',
    writeLatency: '1',
  },

  prometheusRules+:: {
    local SLODays = $._config.SLOs.days + 'd',
    local verbs = [
      { type: 'read', selector: $._config.readSelector },
      { type: 'write', selector: $._config.writeSelector },
    ],

    groups+: [
      {
        name: 'micrometer-availability.rules',
        interval: '3m',
        rules:
          [
            {
              record: 'status_method:micrometer_request_total:increase1h',
              expr: |||
                sum by (application,status,method) (increase(http_server_requests_seconds_count[1h]))
              |||,
            },
          ]
          +
          [
            {
              record: 'status_method:micrometer_request_total:increase%s' % SLODays,
              expr: |||
                avg_over_time(status_method:micrometer_request_total:increase1h[%s]) * 24 * %d
              ||| % [SLODays, $._config.SLOs.days],
            },
          ]
          +
          [
            {
              record: 'status:micrometer_request_total:increase%s' % SLODays,
              expr: |||
                sum by (application, status) (status_method:micrometer_request_total:increase%s{%s})
              ||| % [SLODays, verb.selector],
              labels: {
                verb: verb.type,
              },
            }
            for verb in verbs
          ]
          // TODO: recording availability by application label
          // +
          // [
          //   {
          //     record: 'micrometer_request:availability%s' % SLODays,
          //     expr: |||
          //       1 - (
          //         # errors
          //         sum by (application) ((status:micrometer_request_total:increase%(SLODays)s{status=~"5.."}) or vector(0))
          //       )
          //       /
          //       sum by (application) (status:micrometer_request_total:increase%(SLODays)s)
          //     ||| % { SLODays: SLODays },
          //     labels: {
          //       verb: 'all',
          //     },
          //   },
          //   {
          //     record: 'micrometer_request:availability%s' % SLODays,
          //     expr: |||
          //       1 - (
          //         # errors
          //         sum by (application) ((status:micrometer_request_total:increase%(SLODays)s{verb="read",status=~"5.."}) or vector(0))
          //       )
          //       /
          //       sum by (application) (status:micrometer_request_total:increase%(SLODays)s{verb="read"})
          //     ||| % { SLODays: SLODays },
          //     labels: {
          //       verb: 'read',
          //     },
          //   },
          //   {
          //     record: 'micrometer_request:availability%s' % SLODays,
          //     expr: |||
          //       1 - (
          //         # errors
          //         sum by (application) (status:micrometer_request_total:increase%(SLODays)s{verb="write",status=~"5.."}) or vector(0)
          //       )
          //       /
          //       sum by (application) (status:micrometer_request_total:increase%(SLODays)s{verb="write"})
          //     ||| % { SLODays: SLODays },
          //     labels: {
          //       verb: 'write',
          //     },
          //   },
          // ]
          +
          [
            {
              record: 'status:micrometer_request_total:rate5m',
              expr: |||
                sum by (application,status,uri) (rate(http_server_requests_seconds_count{%s}[5m]))
              ||| % verb.selector,
              labels: {
                verb: verb.type,
              },
            }
            for verb in verbs
          ],
      },
    ],
  },
}
