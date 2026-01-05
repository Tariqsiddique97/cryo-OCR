<?php

namespace App\Services;

/**
 * Provides the hard-coded checklists for vehicle inspections.
 * This is where you can edit the items directly in the code.
 *
 * 'id' is the unique key to be saved in the database.
 * 'label' is the display text for the app.
 * 'is_safety' marks items that are safety-related (from the * in the image).
 * This determines the "Red Flag" logic.
 */
class InspectionChecklistService
{
    /**
     * Get the checklist for a given vehicle type.
     *
     * @param string $type ('tractor' or 'trailer')
     * @return array
     */
    public function getChecklist(string $type): array
    {
        if ($type === 'tractor') {
            return $this->getTractorChecklist();
        }

        if ($type === 'trailer') {
            return $this->getTrailerChecklist();
        }

        return [];
    }

    /**
     * Checklist for Tractors.
     * EDIT THIS ARRAY TO CHANGE THE TRACTOR CHECKLIST
     */
    private function getTractorChecklist(): array
    {
        return [
            [
                'group' => '1. CAB / TRACTOR: CHK IF REPAIR IS NEEDED',
                'items' => [
                    ['id' => 'oil_level', 'label' => 'Oil Level / Oil Pressure', 'is_safety' => true],
                    ['id' => 'transmission', 'label' => 'Transmission', 'is_safety' => true],
                    ['id' => 'coolant_level', 'label' => 'Coolant Level / Operating Temp', 'is_safety' => true],
                    ['id' => 'steering', 'label' => 'Steering', 'is_safety' => true],
                    ['id' => 'gauges', 'label' => 'Instrumentation / Guages', 'is_safety' => true],
                    ['id' => 'spare_fuse', 'label' => 'Spare fuse / Breakers', 'is_safety' => true],
                    ['id' => 'glass_mirrors', 'label' => 'Glass / Mirrors', 'is_safety' => true],
                    ['id' => 'cab_lighting', 'label' => 'Cab Lighting', 'is_safety' => true],
                    ['id' => 'air_buzzer', 'label' => 'Air Build up / Buzzer / Lights', 'is_safety' => true],
                    ['id' => 'triangles', 'label' => 'Triangles', 'is_safety' => true],
                    ['id' => 'wipers', 'label' => 'Windshield Washer / Wipers', 'is_safety' => true],
                    ['id' => 'trailer_light_cord', 'label' => 'Trailer Light Cord', 'is_safety' => true],
                    ['id' => 'fire_ext', 'label' => 'Fire Ext / c current inspection', 'is_safety' => true],
                    ['id' => 'spill_kit', 'label' => 'Spill Kit', 'is_safety' => true],
                    ['id' => 'horn_air_electric', 'label' => 'Horn - Air & Electric', 'is_safety' => true],
                    ['id' => 'collision_avoidance', 'label' => 'Collision Avoidance Sys', 'is_safety' => true],
                    ['id' => 'drivecam', 'label' => 'DriveCam', 'is_safety' => true],
                    ['id' => 'on_board_computer', 'label' => 'On-Board Computer', 'is_safety' => true],
                    ['id' => 'frame_crossmembers', 'label' => 'Frame & Crossmembers', 'is_safety' => true],
                    ['id' => 'brake_air_lines', 'label' => 'Break Air Lines', 'is_safety' => true],
                ]
            ],
            [
                'group' => '2. VISUAL OUTER - CHECK IF REPAIR IS NEEDED',
                'items' => [
                    ['id' => 'accident_damage', 'label' => 'Accident Damage', 'is_safety' => true],
                    ['id' => 'turn_signals', 'label' => 'Turn Signals / Flashers', 'is_safety' => true],
                    ['id' => 'axles_hubs_oil', 'label' => 'Axles & Hubs- Oil Level', 'is_safety' => true],
                    ['id' => 'brake_lights', 'label' => 'Brake Lights', 'is_safety' => true],
                    ['id' => 'springs_air_bags', 'label' => 'Springs / Air Bags', 'is_safety' => true],
                    ['id' => 'reflectors', 'label' => 'Reflectors', 'is_safety' => true],
                    ['id' => 'rims_hubs_lugs', 'label' => 'Rims / Hubs / Lugs (Indicators)', 'is_safety' => true],
                    ['id' => 'conspicuity_tape', 'label' => 'Conspicuity Tape', 'is_safety' => true],
                    ['id' => 'wheel_chocks', 'label' => 'Wheel Chocks & Cones', 'is_safety' => true],
                    ['id' => 'exhaust_regen', 'label' => 'Exhaust / Regen', 'is_safety' => true],
                    ['id' => 'tires_inflation', 'label' => 'Tires / Air Inflation Devices', 'is_safety' => true],
                    ['id' => 'fifth_wheel', 'label' => 'Fifth Wheel', 'is_safety' => true],
                    ['id' => 'braking_system', 'label' => 'Braking System', 'is_safety' => true],
                    ['id' => 'truck_body_flaps', 'label' => 'Truck Body - Flaps', 'is_safety' => true],
                    ['id' => 'headlights', 'label' => 'Headlights- Low & High', 'is_safety' => true],
                    ['id' => 'permits_reg', 'label' => 'Permits, Regs, Ins.', 'is_safety' => true],
                    ['id' => 'coid_dot', 'label' => 'Co.id. / DOT #', 'is_safety' => true],
                    ['id' => 'hyd_hoses_couplers', 'label' => 'Hyd Hoses / Couplers', 'is_safety' => true],
                ]
            ],
        ];
    }

    /**
     * Checklist for Trailers.
     * EDIT THIS ARRAY TO CHANGE THE TRAILER CHECKLIST
     */
    private function getTrailerChecklist(): array
    {
        return [
            [
                'group' => '1. TRAILER: CHK IF REPAIR IS NEEDED',
                'items' => [
                    ['id' => 'body_damage', 'label' => 'Body Condition / Accident Damange', 'is_safety' => true],
                    ['id' => 'hyd_hoses_couplers', 'label' => 'Hyd Hoses / Couplers', 'is_safety' => true],
                    ['id' => 'landing_gear', 'label' => 'Landing Gear / Frame', 'is_safety' => true],
                    ['id' => 'brake_air_lines', 'label' => 'Brake Air Lines', 'is_safety' => true],
                    ['id' => 'springs_hangers_axles', 'label' => 'Springs / Airbags / Hangers / Axles', 'is_safety' => true],
                    ['id' => 'aux_engine', 'label' => 'Aux. Engine System', 'is_safety' => true],
                    ['id' => 'braking_system', 'label' => 'Braking System', 'is_safety' => true],
                    ['id' => 'oil_level_gauges', 'label' => 'Oil Level / Coolant / Charging Guages', 'is_safety' => true],
                    ['id' => 'air_hoses_no_leaks', 'label' => 'Air Hoses - No Leaks', 'is_safety' => true],
                    ['id' => 'meter_totalizer', 'label' => 'Meter totalizer', 'is_safety' => true],
                    ['id' => 'tires_inflation', 'label' => 'Tires / Air Inflation Devices', 'is_safety' => true],
                    ['id' => 'vaporizor', 'label' => 'Vaporizor', 'is_safety' => true],
                    ['id' => 'rims_hubs_lugs', 'label' => 'Rims / Hubs / Lugs (Indicators)', 'is_safety' => true],
                    ['id' => 'anti_tow', 'label' => 'Anti-Tow System', 'is_safety' => true],
                    ['id' => 'coupling_device', 'label' => 'Coupling Device', 'is_safety' => true],
                    ['id' => 'chain', 'label' => 'Chain', 'is_safety' => true],
                    ['id' => 'lights', 'label' => 'Lights', 'is_safety' => true],
                    ['id' => 'rear_comp_clean', 'label' => 'Rear Comp clean & free of debris', 'is_safety' => true],
                    ['id' => 'tail_stop_turn', 'label' => 'Tail / Stop / Turn Lights', 'is_safety' => true],
                    ['id' => 'air_brake_valve', 'label' => 'Air Brake Valve Lock', 'is_safety' => true],
                    ['id' => 'conspicuity_tape', 'label' => 'Conspicuity Tape', 'is_safety' => true],
                    ['id' => 'special_permit', 'label' => 'Special Permit', 'is_safety' => true],
                    ['id' => 'permits_placards', 'label' => 'Permits / Placards / Decals', 'is_safety' => true],
                    ['id' => 'tube_bands', 'label' => 'Tube Bands', 'is_safety' => true],
                    ['id' => 'product_labeling', 'label' => 'Product Labeling', 'is_safety' => true],
                    ['id' => 'piping_valves', 'label' => 'Piping / Valves', 'is_safety' => true],
                    ['id' => 'transfer_hose_plug', 'label' => 'Transfer Hose-Plug', 'is_safety' => true],
                    ['id' => 'vent_tubes_caps', 'label' => 'Vent tubes / Caps', 'is_safety' => true],
                    ['id' => 'hose_tube_secure', 'label' => 'Hose tube securs', 'is_safety' => true],
                    ['id' => 'safety_rails', 'label' => 'Safety Rails', 'is_safety' => true],
                    ['id' => 'piping_leaks', 'label' => 'Piping Leaks', 'is_safety' => true],
                    ['id' => 'pumps', 'label' => 'Pumps', 'is_safety' => true],
                    ['id' => 'doors_hinges_locks', 'label' => 'Doors, Hinges, Locks', 'is_safety' => true],
                ]
            ],
        ];
    }
}