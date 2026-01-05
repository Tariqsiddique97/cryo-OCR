<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trip Report #{{ $trip->id }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            color: #333;
            line-height: 1.6;
        }
        .container {
            width: 100%;
            margin: 0 auto;
            padding: 20px;
        }
        h2 {
            font-size: 24px;
            font-weight: bold;
            color: #000;
            border-bottom: 2px solid #f0f0f0;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        h3 {
            font-size: 18px;
            font-weight: bold;
            color: #222;
            margin-top: 30px;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
            padding-bottom: 5px;
        }
        .info-card {
            background-color: #f9f9f9;
            border: 1px solid #e3e3e3;
            border-radius: 5px;
            padding: 20px;
            margin-bottom: 20px;
        }
        dl {
            width: 100%;
        }
        .dl-row {
            display: block;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        /* Clearfix for floats */
        .dl-row::after {
            content: "";
            display: table;
            clear: both;
        }
        dt {
            font-weight: bold;
            color: #555;
            width: 30%; /* Adjust width as needed */
            float: left;
            padding-right: 10px;
            box-sizing: border-box;
        }
        dd {
            width: 70%; /* Adjust width as needed */
            float: left;
            margin-left: 0;
            box-sizing: border-box;
        }
        .stop-box {
            border: 1px solid #ccc;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 15px;
            background: #fff;
        }
        .stop-header {
            font-size: 16px;
            font-weight: bold;
            color: #000;
            margin-bottom: 10px;
        }
        .no-stops {
            color: #777;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Trip Details: #{{ $trip->id }}</h2>

        <!-- Trip Information -->
        <div class="info-card">
            <h3>Trip Information</h3>
            <dl>
                <div class="dl-row">
                    <dt>Driver</dt>
                    <dd>{{ $trip->driver->name ?? 'N/A' }}</dd>
                </div>
                <div class="dl-row">
                    <dt>Tractor Number</dt>
                    <dd>{{ $trip->tractor->number ?? 'Not Assigned' }}</dd>
                </div>
                <div class="dl-row">
                    <dt>Trailer Number</dt>
                    <dd>{{ $trip->trailer->number ?? 'Not Assigned' }}</dd>
                </div>
                <div class="dl-row">
                    <dt>Total Trip Miles</dt>
                    <dd>{{ $trip->total_trip_miles ?? '-' }}</dd>
                </div>
                <div class="dl-row">
                    <dt>Total Quantity</dt>
                    <dd>{{ $trip->total_quantity ?? '-' }}</dd>
                </div>
                <!-- Status field is intentionally removed as requested -->
            </dl>
        </div>

        <!-- Stops Information -->
        <div>
            <h3>Stops Details</h3>
            <div class="mt-4 space-y-6">
                @forelse($trip->stops as $stop)
                    <div class="stop-box">
                        <div class="stop-header">
                            {{ $stop->sequence_number }}. {{ $stop->name }}
                            <!-- Status span is intentionally removed as requested -->
                        </div>
                        
                        <dl class="mt-2 text-sm">
                            @php
                                $fields = [
                                    'start_time',
                                    'end_time',
                                    'tank_number',
                                    'full_trycock',
                                    'attn_driver_maintain',
                                    'psi_value',
                                    'levels_value',
                                    'level_before_value',
                                    'level_after_value',
                                    'psi_before_value',
                                    'psi_after_value',
                                    'quantity_value',
                                    'odometer_value',
                                ];
                            @endphp
                            @foreach ($fields as $field)
                                <div class="dl-row">
                                    <dt>{{ ucwords(str_replace('_', ' ', $field)) }}</dt>
                                    <dd>{{ $stop->$field ?? '-' }}</dd>
                                </div>
                            @endforeach
                        </dl>
                    </div>
                @empty
                    <p class="no-stops">No stops have been recorded for this trip.</p>
                @endforelse
            </div>
        </div>
    </div>
</body>
</html>
