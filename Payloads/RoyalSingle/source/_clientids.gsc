init()
{
    level thread rs_connect();
}

rs_connect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread rs_spawn();
    }
}

rs_spawn()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( !isdefined( self.rs_loaded ) )
        {
            self.rs_loaded = true;
            self.rs_open = false;
            self thread rs_buttons();
            self iprintln( "^2Royal Single ^7ready - L2 + R3" );
        }
    }
}

rs_buttons()
{
    self endon( "disconnect" );

    for (;;)
    {
        if ( !self.rs_open && self adsbuttonpressed() && self meleebuttonpressed() )
        {
            self.rs_open = true;
            self rs_draw();
            while ( self adsbuttonpressed() || self meleebuttonpressed() )
                wait 0.05;
        }
        else if ( self.rs_open && self meleebuttonpressed() )
        {
            self.rs_open = false;
            self rs_clear();
            while ( self meleebuttonpressed() )
                wait 0.05;
        }
        else if ( self.rs_open && self usebuttonpressed() )
        {
            self thread rs_unlock_everything();
            while ( self usebuttonpressed() )
                wait 0.05;
        }

        wait 0.05;
    }
}

rs_draw()
{
    self rs_clear();
    self.rs_bg = self rs_shader( "white", 70, 92, 340, 118, ( 0.02, 0.02, 0.02 ), 0.88, 1 );
    self.rs_bar = self rs_shader( "white", 70, 92, 340, 3, ( 0.00, 0.70, 0.95 ), 1, 2 );
    self.rs_select = self rs_shader( "white", 82, 139, 316, 28, ( 0.00, 0.32, 0.90 ), 0.90, 3 );
    self.rs_title = self rs_text( "ROYAL RECOVERY", 84, 104, 1.35, ( 1, 1, 1 ), 4 );
    self.rs_credit = self rs_text( "BY IALS96", 315, 108, 0.75, ( 0.00, 0.70, 0.95 ), 4 );
    self.rs_option = self rs_text( "UNLOCK EVERYTHING", 95, 145, 1.05, ( 1, 1, 1 ), 4 );
    self.rs_help = self rs_text( "[{+usereload}] SELECT   [{+melee}] CLOSE", 86, 180, 0.75, ( 0.78, 0.78, 0.78 ), 4 );
}

rs_shader( shader, x, y, width, height, color, alpha, sort )
{
    elem = newclienthudelem( self );
    elem.elemtype = "icon";
    elem.x = x;
    elem.y = y;
    elem.alignx = "LEFT";
    elem.aligny = "TOP";
    elem.horzalign = "LEFT";
    elem.vertalign = "TOP";
    elem.color = color;
    elem.alpha = alpha;
    elem.sort = sort;
    elem.foreground = true;
    elem setshader( shader, width, height );
    return elem;
}

rs_text( text, x, y, scale, color, sort )
{
    elem = newclienthudelem( self );
    elem.font = "default";
    elem.fontscale = scale;
    elem.x = x;
    elem.y = y;
    elem.alignx = "LEFT";
    elem.aligny = "TOP";
    elem.horzalign = "LEFT";
    elem.vertalign = "TOP";
    elem.color = color;
    elem.alpha = 1;
    elem.sort = sort;
    elem.foreground = true;
    elem settext( text );
    return elem;
}

rs_clear()
{
    if ( isdefined( self.rs_bg ) )
        self.rs_bg destroy();
    if ( isdefined( self.rs_bar ) )
        self.rs_bar destroy();
    if ( isdefined( self.rs_select ) )
        self.rs_select destroy();
    if ( isdefined( self.rs_title ) )
        self.rs_title destroy();
    if ( isdefined( self.rs_credit ) )
        self.rs_credit destroy();
    if ( isdefined( self.rs_option ) )
        self.rs_option destroy();
    if ( isdefined( self.rs_help ) )
        self.rs_help destroy();

    self.rs_bg = undefined;
    self.rs_bar = undefined;
    self.rs_select = undefined;
    self.rs_title = undefined;
    self.rs_credit = undefined;
    self.rs_option = undefined;
    self.rs_help = undefined;
}

rs_unlock_everything()
{
    self endon( "disconnect" );

    if ( isdefined( self.rs_unlock_running ) )
    {
        self iprintlnbold( "^1UNLOCK IS ALREADY RUNNING" );
        return;
    }

    self.rs_unlock_running = true;
    self iprintlnbold( "^5UNLOCKING EVERYTHING - PLEASE WAIT" );

    for ( row = 1; row < 256; row++ )
    {
        itemref = tablelookup( "mp/statstable.csv", 0, row, 4 );
        itemclass = tablelookup( "mp/statstable.csv", 0, row, 2 );

        if ( itemref == "" )
            continue;

        valid = issubstr( itemclass, "weapon_" ) || itemclass == "specialty" || itemclass == "bonuscard" || itemclass == "killstreak";
        if ( !valid )
            continue;

        item = int( tablelookup( "mp/statstable.csv", 4, itemref, 0 ) );
        if ( item <= 0 )
            continue;

        self setdstat( "itemStats", item, "purchased", 1 );
        if ( issubstr( itemclass, "weapon_" ) )
        {
            self setdstat( "itemStats", item, "xp", 665535 );
            self setdstat( "itemStats", item, "plevel", 2 );
        }
        wait 0.02;
    }

    weapons = strtok( "870mcs_mp,an94_mp,as50_mp,ballista_mp,beretta93r_mp,crossbow_mp,dsr50_mp,evoskorpion_mp,fiveseven_mp,fhj18_mp,fnp45_mp,hamr_mp,hk416_mp,insas_mp,judge_mp,kard_mp,knife_ballistic_mp,knife_held_mp,ksg_mp,lsat_mp,mk48_mp,mp7_mp,pdw57_mp,peacekeeper_mp,qbb95_mp,qcw05_mp,riotshield_mp,sa58_mp,saiga12_mp,saritch_mp,vector_mp,scar_mp,sig556_mp,smaw_mp,srm1216_mp,svu_mp,tar21_mp,type95_mp,usrpg_mp,xm8_mp", "," );
    camostats = strtok( "headshots,kills,longshot_kill,noAttKills,noPerkKills,multikill_2,multikill_3,killstreak_5,revenge_kill,direct_hit_kills,backstabber_kill,kill_enemy_when_injured,ballistic_knife_kill,noLethalKills,primary_mastery,secondary_mastery,weapons_mastery", "," );

    foreach ( weapon in weapons )
    {
        foreach ( stat in camostats )
            self addweaponstat( weapon, stat, 10000 );
        wait 0.04;
    }

    challenges = strtok( "killstreak_10,killstreak_15,killstreak_20,killstreak_30,round_win_no_deaths,last_man_defeat_3_enemies,most_kills_least_deaths,kill_2_enemies_capturing_your_objective,capture_b_first_minute,immediate_capture,contest_then_capture,both_bombs_detonate_10_seconds,kill_enemy_who_killed_teammate,kill_enemy_injuring_teammate,defused_bomb_last_man_alive,elimination_and_last_player_alive,killed_bomb_planter,killed_bomb_defuser,kill_flag_carrier,defend_flag_carrier,reload_then_kill_dualclip,kill_with_remote_control_ai_tank,killstreak_5_with_sentry_gun,kill_with_remote_control_sentry_gun,killstreak_5_with_death_machine,kill_with_both_primary_weapons,kill_with_loadout_weapon_with_3_attachments,kill_with_2_perks_same_category,kill_while_uav_active,kill_while_cuav_active,kill_while_satellite_active,kill_after_tac_insert,kill_enemy_revealed_by_sensor,kill_while_emp_active,killstreak_5_dogs,kill_flashed_enemy,kill_concussed_enemy,kill_shocked_enemy,shock_enemy_then_stab_them,mantle_then_kill,kill_enemy_with_picked_up_weapon,killstreak_5_picked_up_weapon,kill_enemy_shoot_their_explosive,kill_enemy_while_crouched,kill_enemy_while_prone,kill_prone_enemy,get_final_kill,destroy_equipment,destroy_explosive,destroy_turret,destroy_aircraft", "," );
    foreach ( challenge in challenges )
    {
        self addplayerstat( challenge, 10000 );
        wait 0.01;
    }

    self.rs_unlock_running = undefined;
    self iprintlnbold( "^2EVERYTHING UNLOCKED" );
    self iprintln( "^3END THE MATCH NORMALLY TO SAVE" );
}
