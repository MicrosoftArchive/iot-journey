﻿using System;
using System.IO;
using System.Threading;
using Microsoft.Practices.IoTJourney.Monitoring.EventProcessor.ConsoleHost.Formatters;
using Microsoft.Practices.IoTJourney.Monitoring.EventProcessor.ConsoleHost.Sinks;

namespace Microsoft.Practices.IoTJourney.Monitoring.EventProcessor.ConsoleHost
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            var configuration = Configuration.GetCurrentConfiguration();
            var monitor = EventHubMonitorFactory.CreateAsync(configuration).Result;

            var formatter = new CsvEventTextFormatter();
            var filename = string.Format(
                "Data\\{0}-{1}.csv", configuration.ConsumerGroupName,
                DateTime.Now.ToString("yyyy-MM-dd-hh-mm"));

            var sink = new FlatFileSink(filename, formatter, true);

            var outputDir = Path.Combine(Environment.CurrentDirectory, "Data");
            if (!Directory.Exists(outputDir))
            {
                Directory.CreateDirectory(outputDir);
            }

            monitor.Subscribe(@event =>
            {
                sink.OnNext(@event);

                var originalColor = Console.ForegroundColor;
                if (@event.IsStale)
                {
                    Console.ForegroundColor = ConsoleColor.DarkCyan;
                }

                Console.WriteLine("Partition {0}", @event.PartitionId);
                Console.WriteLine("----------");
                Console.WriteLine("- LastCheckpointTimeUtc: {0}", @event.LastCheckpointTimeUtc);
                Console.WriteLine("- LastEnqueuedTimeUtc: {0:}", @event.LastEnqueuedTimeUtc);
                Console.WriteLine("- IncomingEventsPerSecond: {0:0.#}", @event.IncomingEventsPerSecond);
                Console.WriteLine("- IncomingBytesPerSecond: {0}", @event.IncomingBytesPerSecond);
                Console.WriteLine("- OutgoingEventsPerSecond: {0:0.#}", @event.OutgoingEventsPerSecond);
                Console.WriteLine("- OutgoingBytesPerSecond: {0}", @event.OutgoingBytesPerSecond);
                Console.WriteLine("- UnprocessedEvents: {0}", @event.UnprocessedEvents);
                Console.WriteLine("");

                Console.ForegroundColor = originalColor;

            });

            Console.ReadKey();
        }
    }
}