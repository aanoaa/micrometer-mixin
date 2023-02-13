{
  _config+:: {
    SLOs: {
      days: 30,     // The number of days we alert on burning too much error budget for.
      target: 0.99, // The target percentage of availability between 0-1. (0.99 = 99%, 0.999 = 99.9%)
      windows: [
        { severity: 'critical', 'for': '2m', long: '1h', short: '5m', factor: 14.4 },
        { severity: 'critical', 'for': '15m', long: '6h', short: '30m', factor: 6 },
        { severity: 'warning', 'for': '1h', long: '1d', short: '2h', factor: 3 },
        { severity: 'warning', 'for': '3h', long: '3d', short: '6h', factor: 1 },
      ],
    },

    // multi application dashboards by applicationLabel
    applicationLabel: 'application',

    // Default datasource name
    datasourceName: 'default',

    // Datasource instance filter regex
    datasourceFilterRegex: '',

    dashboardNamePrefix: 'micrometer / ',
    dashboardTags: ['micrometer'],
  },
}
