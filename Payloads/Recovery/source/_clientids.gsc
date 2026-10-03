init()
{
    level thread recovery_connect_loop();
}

recovery_connect_loop()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread recovery_spawn_loop();
    }
}

recovery_spawn_loop()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( !isdefined( self.recovery_loaded ) )
        {
            self.recovery_loaded = true;
            self recovery_init();
            self thread recovery_input_loop();
            self iprintlnbold( "^2RECOVERY MENU BY IALS96 ^7READY" );
        }
    }
}

recovery_init()
{
    self.recovery_open = false;
    self.recovery_menu = "main";
    self.recovery_parent = "";
    self.recovery_cursor = 0;
    self.recovery_scroll = 0;
    self.recovery_visible = 8;
    self.recovery_chosen_level = 1;
    self recovery_create_hud();
    self recovery_build_menu( "main", "" );
    self recovery_hide_hud();
}

recovery_create_hud()
{
    self.rm_lines = [];
    self.rm_bg = self recovery_shader( "white", 62, 78, 330, 278, ( 0.02, 0.02, 0.02 ), 0.88, 1 );
    self.rm_header = self recovery_shader( "white", 62, 78, 330, 36, ( 0.04, 0.04, 0.04 ), 0.98, 2 );
    self.rm_top = self recovery_shader( "white", 62, 76, 330, 2, ( 0.00, 0.72, 0.95 ), 1, 3 );
    self.rm_divider = self recovery_shader( "white", 62, 113, 330, 2, ( 0.00, 0.72, 0.95 ), 1, 3 );
    self.rm_bottom = self recovery_shader( "white", 62, 354, 330, 2, ( 0.00, 0.72, 0.95 ), 1, 3 );
    self.rm_cursor_hud = self recovery_shader( "white", 69, 126, 316, 22, ( 0.00, 0.34, 0.92 ), 0.92, 4 );

    self.rm_title = self recovery_text( "RECOVERY MENU", 76, 88, 1.35, ( 1, 1, 1 ), 5 );
    self.rm_credit = self recovery_text( "BY IALS96", 285, 90, 0.75, ( 0.00, 0.72, 0.95 ), 5 );

    for ( i = 0; i < self.recovery_visible; i++ )
        self.rm_lines[i] = self recovery_text( "", 82, 132 + i * 25, 0.95, ( 0.82, 0.82, 0.82 ), 5 );

    self.rm_controls = self recovery_text( "[{+frag}] UP  [{+smoke}] DOWN  [{+usereload}] SELECT  [{+melee}] BACK", 76, 330, 0.66, ( 0.75, 0.75, 0.75 ), 5 );
}

recovery_shader( shader, x, y, width, height, color, alpha, sort )
{
    elem = newclienthudelem( self );
    elem.x = x;
    elem.y = y;
    elem.alignx = "left";
    elem.aligny = "top";
    elem.horzalign = "user_left";
    elem.vertalign = "user_top";
    elem.color = color;
    elem.alpha = alpha;
    elem.sort = sort;
    elem.foreground = true;
    elem setshader( shader, width, height );
    return elem;
}

recovery_text( text, x, y, scale, color, sort )
{
    elem = newclienthudelem( self );
    elem.font = "default";
    elem.fontscale = scale;
    elem.x = x;
    elem.y = y;
    elem.alignx = "left";
    elem.aligny = "top";
    elem.horzalign = "user_left";
    elem.vertalign = "user_top";
    elem.color = color;
    elem.alpha = 1;
    elem.sort = sort;
    elem.foreground = true;
    elem settext( text );
    return elem;
}

recovery_set_hud_alpha( alpha )
{
    self.rm_bg.alpha = alpha * 0.88;
    self.rm_header.alpha = alpha * 0.98;
    self.rm_top.alpha = alpha;
    self.rm_divider.alpha = alpha;
    self.rm_bottom.alpha = alpha;
    self.rm_cursor_hud.alpha = alpha * 0.92;
    self.rm_title.alpha = alpha;
    self.rm_credit.alpha = alpha;
    self.rm_controls.alpha = alpha;

    for ( i = 0; i < self.recovery_visible; i++ )
        self.rm_lines[i].alpha = alpha;
}

recovery_show_hud()
{
    self recovery_set_hud_alpha( 1 );
    self recovery_refresh();
}

recovery_hide_hud()
{
    self recovery_set_hud_alpha( 0 );
}

recovery_input_loop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        if ( !self.recovery_open )
        {
            if ( self adsbuttonpressed() && self meleebuttonpressed() )
            {
                self.recovery_open = true;
                self recovery_show_hud();
                self playsoundtoplayer( "wpn_tomahawk_catch_plr", self );
                while ( self adsbuttonpressed() || self meleebuttonpressed() )
                    wait 0.05;
            }
        }
        else if ( self meleebuttonpressed() )
        {
            if ( self.recovery_parent == "" )
            {
                self.recovery_open = false;
                self recovery_hide_hud();
            }
            else
            {
                parent = self.recovery_parent;
                self recovery_build_menu( parent, self recovery_parent_for( parent ) );
            }

            self playsoundtoplayer( "zmb_plane_takeoff", self );
            while ( self meleebuttonpressed() )
                wait 0.05;
        }
        else if ( self fragbuttonpressed() )
        {
            self recovery_move( -1 );
            while ( self fragbuttonpressed() )
                wait 0.05;
        }
        else if ( self secondaryoffhandbuttonpressed() )
        {
            self recovery_move( 1 );
            while ( self secondaryoffhandbuttonpressed() )
                wait 0.05;
        }
        else if ( self usebuttonpressed() )
        {
            self recovery_select();
            while ( self usebuttonpressed() )
                wait 0.05;
        }

        wait 0.05;
    }
}

recovery_parent_for( menu )
{
    if ( menu == "chooselevel" )
        return "rank";

    if ( menu == "rank" || menu == "stats" || menu == "medals" || menu == "save" )
        return "main";

    return "";
}

recovery_move( amount )
{
    self.recovery_cursor += amount;

    if ( self.recovery_cursor < 0 )
        self.recovery_cursor = self.recovery_options.size - 1;

    if ( self.recovery_cursor >= self.recovery_options.size )
        self.recovery_cursor = 0;

    if ( self.recovery_cursor < self.recovery_scroll )
        self.recovery_scroll = self.recovery_cursor;

    if ( self.recovery_cursor >= self.recovery_scroll + self.recovery_visible )
        self.recovery_scroll = self.recovery_cursor - self.recovery_visible + 1;

    self playsoundtoplayer( "zmb_plane_fall", self );
    self recovery_refresh();
}

recovery_select()
{
    if ( !isdefined( self.recovery_functions[self.recovery_cursor] ) )
        return;

    fn = self.recovery_functions[self.recovery_cursor];
    arg = self.recovery_arguments[self.recovery_cursor];
    self playsoundtoplayer( "evt_spawn", self );
    self thread [[ fn ]]( arg );
}

recovery_add( text, function, argument )
{
    index = self.recovery_options.size;
    self.recovery_options[index] = text;
    self.recovery_functions[index] = function;
    self.recovery_arguments[index] = argument;
}

recovery_build_menu( menu, parent )
{
    self.recovery_menu = menu;
    self.recovery_parent = parent;
    self.recovery_cursor = 0;
    self.recovery_scroll = 0;
    self.recovery_options = [];
    self.recovery_functions = [];
    self.recovery_arguments = [];

    if ( menu == "main" )
    {
        self recovery_add( "RANK & LEVEL", ::recovery_open_menu, "rank" );
        self recovery_add( "MAX WEAPON RANKS", ::recovery_max_weapons, 0 );
        self recovery_add( "STATS", ::recovery_open_menu, "stats" );
        self recovery_add( "MEDALS", ::recovery_open_menu, "medals" );
        self recovery_add( "COMPLETE UNLOCK + CAMOS", ::recovery_complete_unlock, 0 );
        self recovery_add( "UNLOCK ALL CALLING CARDS", ::recovery_calling_cards, 0 );
        self recovery_add( "UNLOCK ALL ACHIEVEMENTS", ::recovery_achievements, 0 );
        self recovery_add( "SAVE / PROFILE", ::recovery_open_menu, "save" );
    }
    else if ( menu == "rank" )
    {
        self recovery_add( "LEVEL 55 + MAX XP", ::recovery_level55_maxxp, 0 );
        self recovery_add( "LEVEL 55", ::recovery_set_level, 55 );
        self recovery_add( "LEVEL +1", ::recovery_level_plus_one, 0 );
        self recovery_add( "CHOOSE LEVEL", ::recovery_open_menu, "chooselevel" );
    }
    else if ( menu == "chooselevel" )
    {
        self recovery_add( "SET SELECTED LEVEL: " + self.recovery_chosen_level, ::recovery_apply_chosen_level, 0 );
        self recovery_add( "SELECTED LEVEL +1", ::recovery_change_chosen_level, 1 );
        self recovery_add( "SELECTED LEVEL +5", ::recovery_change_chosen_level, 5 );
        self recovery_add( "SELECTED LEVEL -1", ::recovery_change_chosen_level, -1 );
        self recovery_add( "SELECTED LEVEL -5", ::recovery_change_chosen_level, -5 );
        self recovery_add( "SELECT LEVEL 55", ::recovery_choose_55, 0 );
    }
    else if ( menu == "stats" )
    {
        self recovery_add( "KILLS +1,000,000", ::recovery_add_stat, "kills|1000000" );
        self recovery_add( "KILLS +100,000", ::recovery_add_stat, "kills|100000" );
        self recovery_add( "KILLS +10,000", ::recovery_add_stat, "kills|10000" );
        self recovery_add( "WINS +1,000,000", ::recovery_add_stat, "wins|1000000" );
        self recovery_add( "WINS +1,000", ::recovery_add_stat, "wins|1000" );
        self recovery_add( "DEATHS +1,000", ::recovery_add_stat, "deaths|1000" );
        self recovery_add( "LOSSES +100", ::recovery_add_stat, "losses|100" );
        self recovery_add( "ASSISTS +10,000", ::recovery_add_stat, "assist|10000" );
        self recovery_add( "SCORE +10,000,000", ::recovery_add_stat, "score|10000000" );
        self recovery_add( "HEADSHOTS +100,000", ::recovery_add_stat, "headshots|100000" );
        self recovery_add( "TIME PLAYED +7 DAYS", ::recovery_add_stat, "time_played_total|604800" );
        self recovery_add( "TIME PLAYED +30 DAYS", ::recovery_add_stat, "time_played_total|2592000" );
    }
    else if ( menu == "medals" )
    {
        self recovery_add( "ALL MEDALS x1000", ::recovery_all_medals, 1000 );
        self recovery_add( "ALL MEDALS x100", ::recovery_all_medals, 100 );
        self recovery_add( "KILLSTREAK 10 x1000", ::recovery_add_game_stat, "killstreak_10|1000" );
        self recovery_add( "KILLSTREAK 15 x1000", ::recovery_add_game_stat, "killstreak_15|1000" );
        self recovery_add( "KILLSTREAK 20 x1000", ::recovery_add_game_stat, "killstreak_20|1000" );
        self recovery_add( "KILLSTREAK 30 x1000", ::recovery_add_game_stat, "killstreak_30|1000" );
        self recovery_add( "TRIPLE KILL x1000", ::recovery_add_game_stat, "multikill_3|1000" );
    }
    else if ( menu == "save" )
    {
        self recovery_add( "SAVE PROFILE", ::recovery_save_profile, 0 );
        self recovery_add( "SAVE & END GAME (KEEP CHANGES)", ::recovery_save_end, 0 );
        self recovery_add( "RE-APPLY RANKED MODE", ::recovery_ranked_mode, 0 );
    }

    self recovery_refresh();
}

recovery_open_menu( menu )
{
    self recovery_build_menu( menu, self.recovery_menu );
}

recovery_refresh()
{
    if ( !isdefined( self.recovery_options ) || self.recovery_options.size == 0 )
        return;

    if ( self.recovery_scroll > self.recovery_options.size - self.recovery_visible )
        self.recovery_scroll = int( max( 0, self.recovery_options.size - self.recovery_visible ) );

    for ( i = 0; i < self.recovery_visible; i++ )
    {
        option = i + self.recovery_scroll;

        if ( option < self.recovery_options.size )
            self.rm_lines[i] settext( self.recovery_options[option] );
        else
            self.rm_lines[i] settext( "" );
    }

    visibleindex = self.recovery_cursor - self.recovery_scroll;
    self.rm_cursor_hud.y = 126 + visibleindex * 25;
    self.rm_title settext( "RECOVERY MENU" );
    self.rm_credit settext( "BY IALS96" );
}

recovery_set_level( displaylevel )
{
    rank = int( displaylevel ) - 1;
    rank = int( max( 0, min( level.maxrank, rank ) ) );
    plevel = self getdstat( "playerstatslist", "plevel", "StatValue" );
    minxp = maps\mp\gametypes\_rank::getrankinfominxp( rank );
    self.pers["rank"] = rank;
    self.pers["rankxp"] = minxp;
    self setdstat( "playerstatslist", "rank", "StatValue", rank );
    self setdstat( "playerstatslist", "rankxp", "StatValue", minxp );
    self setrank( rank, plevel );
    self iprintlnbold( "^2LEVEL " + ( rank + 1 ) + " SET" );
}

recovery_level55_maxxp( unused )
{
    rank = level.maxrank;
    plevel = self getdstat( "playerstatslist", "plevel", "StatValue" );
    maxxp = maps\mp\gametypes\_rank::getrankinfomaxxp( rank );
    self.pers["rank"] = rank;
    self.pers["rankxp"] = maxxp;
    self setdstat( "playerstatslist", "rank", "StatValue", rank );
    self setdstat( "playerstatslist", "rankxp", "StatValue", maxxp );
    self setrank( rank, plevel );
    self iprintlnbold( "^2LEVEL 55 + MAX XP SET" );
}

recovery_level_plus_one( unused )
{
    rank = self getdstat( "playerstatslist", "rank", "StatValue" );
    self recovery_set_level( min( level.maxrank, rank + 1 ) + 1 );
}

recovery_change_chosen_level( amount )
{
    self.recovery_chosen_level += int( amount );
    if ( self.recovery_chosen_level < 1 )
        self.recovery_chosen_level = 1;
    if ( self.recovery_chosen_level > 55 )
        self.recovery_chosen_level = 55;
    self recovery_build_menu( "chooselevel", "rank" );
}

recovery_choose_55( unused )
{
    self.recovery_chosen_level = 55;
    self recovery_build_menu( "chooselevel", "rank" );
}

recovery_apply_chosen_level( unused )
{
    self recovery_set_level( self.recovery_chosen_level );
}

recovery_max_weapons( unused )
{
    self endon( "disconnect" );
    weapons = strtok( "870mcs_mp,an94_mp,as50_mp,ballista_mp,beretta93r_mp,crossbow_mp,dsr50_mp,evoskorpion_mp,fiveseven_mp,fhj18_mp,fnp45_mp,hamr_mp,hk416_mp,insas_mp,judge_mp,kard_mp,knife_ballistic_mp,knife_held_mp,ksg_mp,lsat_mp,mk48_mp,mp7_mp,pdw57_mp,peacekeeper_mp,qbb95_mp,qcw05_mp,riotshield_mp,sa58_mp,saiga12_mp,saritch_mp,vector_mp,scar_mp,sig556_mp,smaw_mp,srm1216_mp,svu_mp,tar21_mp,type95_mp,usrpg_mp,xm8_mp", "," );
    self iprintlnbold( "^5MAXING ALL WEAPON RANKS..." );

    foreach ( weapon in weapons )
    {
        item = getbaseweaponitemindex( weapon );
        if ( item > 0 )
        {
            self setdstat( "itemStats", item, "xp", 665535 );
            self setdstat( "itemStats", item, "plevel", 2 );
        }
        wait 0.02;
    }

    self iprintlnbold( "^2ALL WEAPON RANKS MAXED" );
}

recovery_add_stat( packed )
{
    parts = strtok( packed, "|" );
    self addplayerstat( parts[0], int( parts[1] ) );
    self iprintlnbold( "^2STAT UPDATED: ^7" + parts[0] );
}

recovery_add_game_stat( packed )
{
    parts = strtok( packed, "|" );
    self addgametypestat( parts[0], int( parts[1] ) );
    self iprintlnbold( "^2MEDAL UPDATED: ^7" + parts[0] );
}

recovery_all_medals( amount )
{
    medals = strtok( "killstreak_5,killstreak_10,killstreak_15,killstreak_20,killstreak_30,multikill_2,multikill_3,revenge_kill,longshot_kill,backstabber_kill,headshot_assault_5_onegame,get_final_kill,round_win_no_deaths,last_man_defeat_3_enemies,most_kills_least_deaths,SHUT_OUT,ANNIHILATION", "," );
    foreach ( medal in medals )
        self addgametypestat( medal, int( amount ) );
    self iprintlnbold( "^2ALL MEDALS UPDATED" );
}

recovery_complete_unlock( unused )
{
    self endon( "disconnect" );

    if ( isdefined( self.recovery_unlock_running ) )
    {
        self iprintlnbold( "^1COMPLETE UNLOCK IS ALREADY RUNNING" );
        return;
    }

    self.recovery_unlock_running = true;
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
        wait 0.015;
    }

    weapons = strtok( "870mcs_mp,an94_mp,as50_mp,ballista_mp,beretta93r_mp,crossbow_mp,dsr50_mp,evoskorpion_mp,fiveseven_mp,fhj18_mp,fnp45_mp,hamr_mp,hk416_mp,insas_mp,judge_mp,kard_mp,knife_ballistic_mp,knife_held_mp,ksg_mp,lsat_mp,mk48_mp,mp7_mp,pdw57_mp,peacekeeper_mp,qbb95_mp,qcw05_mp,riotshield_mp,sa58_mp,saiga12_mp,saritch_mp,vector_mp,scar_mp,sig556_mp,smaw_mp,srm1216_mp,svu_mp,tar21_mp,type95_mp,usrpg_mp,xm8_mp", "," );

    foreach ( weapon in weapons )
    {
        self addweaponstat( weapon, "kills", 500 );
        self addweaponstat( weapon, "headshots", 250 );
        self addweaponstat( weapon, "longshot_kill", 50 );
        self addweaponstat( weapon, "revenge_kill", 50 );
        self addweaponstat( weapon, "noAttKills", 250 );
        self addweaponstat( weapon, "noPerkKills", 250 );
        self addweaponstat( weapon, "noLethalKills", 100 );
        self addweaponstat( weapon, "multikill_2", 100 );
        self addweaponstat( weapon, "multikill_3", 50 );
        self addweaponstat( weapon, "killstreak_5", 50 );
        self addweaponstat( weapon, "kill_enemy_one_bullet_shotgun", 300 );
        self addweaponstat( weapon, "kill_enemy_one_bullet_sniper", 300 );
        self addweaponstat( weapon, "direct_hit_kills", 100 );
        self addweaponstat( weapon, "destroyed_aircraft", 200 );
        self addweaponstat( weapon, "primary_mastery", 10000 );
        self addweaponstat( weapon, "secondary_mastery", 10000 );
        self addweaponstat( weapon, "weapons_mastery", 10000 );
        wait 0.04;
    }

    foreach ( weapon in weapons )
    {
        self addweaponstat( weapon, "primary_mastery", 10000 );
        self addweaponstat( weapon, "secondary_mastery", 10000 );
        self addweaponstat( weapon, "weapons_mastery", 10000 );
        wait 0.02;
    }

    self.recovery_unlock_running = undefined;
    self iprintlnbold( "^2EVERYTHING UNLOCKED + ALL CAMOS + DIAMOND" );
    self iprintln( "^3USE SAVE & END GAME TO KEEP CHANGES" );
}

recovery_calling_cards( unused )
{
    challenges = strtok( "killstreak_10,killstreak_15,killstreak_20,killstreak_30,round_win_no_deaths,last_man_defeat_3_enemies,most_kills_least_deaths,kill_2_enemies_capturing_your_objective,capture_b_first_minute,immediate_capture,contest_then_capture,both_bombs_detonate_10_seconds,kill_enemy_who_killed_teammate,kill_enemy_injuring_teammate,defused_bomb_last_man_alive,elimination_and_last_player_alive,killed_bomb_planter,killed_bomb_defuser,kill_flag_carrier,defend_flag_carrier,reload_then_kill_dualclip,kill_with_remote_control_ai_tank,killstreak_5_with_sentry_gun,kill_with_remote_control_sentry_gun,killstreak_5_with_death_machine,kill_enemy_locking_on_with_chopper_gunner,kill_with_loadout_weapon_with_3_attachments,kill_with_both_primary_weapons,kill_with_2_perks_same_category,kill_while_uav_active,kill_while_cuav_active,kill_while_satellite_active,kill_after_tac_insert,kill_enemy_revealed_by_sensor,kill_while_emp_active,killstreak_5_dogs,kill_flashed_enemy,kill_concussed_enemy,kill_enemy_who_shocked_you,kill_shocked_enemy,shock_enemy_then_stab_them,mantle_then_kill,kill_enemy_with_picked_up_weapon,killstreak_5_picked_up_weapon,kill_enemy_shoot_their_explosive,kill_enemy_while_crouched,kill_enemy_while_prone,kill_prone_enemy,kill_every_enemy,pistolHeadshot_10_onegame,headshot_assault_5_onegame,kill_10_enemy_one_bullet_sniper_onegame,kill_10_enemy_one_bullet_shotgun_onegame,kill_enemy_with_tacknife,KILL_CROSSBOW_STACKFIRE,kill_with_claymore,kill_with_hacked_claymore,kill_with_c4,kill_enemy_withcar,stick_explosive_kill_5_onegame,kill_with_cooked_grenade,kill_with_tossed_back_lethal,kill_with_dual_lethal_grenades,perk_movefaster_kills,perk_noname_kills,perk_quieter_kills,perk_longersprint,perk_fastmantle_kills,perk_loudenemies_kills,perk_protection_stun_kills,perk_immune_cuav_kills,perk_gpsjammer_immune_kills,perk_fastweaponswitch_kill_after_swap,perk_scavenger_kills_after_resupply,perk_flak_survive,perk_earnmoremomentum_earn_streak,kill_enemy_through_wall,kill_enemy_through_wall_with_fmj,disarm_hacked_carepackage,destroy_car,kill_nemesis,long_distance_hatchet_kill,longshot_3_onelife,get_final_kill,destroy_rcbomb_with_hatchet,defend_teammate_who_captured_package,destroy_score_streak_with_qrdrone,capture_objective_in_smoke,perk_hacker_destroy,destroy_equipment_with_emp_grenade,destroy_equipment,destroy_5_tactical_inserts,kill_15_with_blade,destroy_explosive,multikill_3_near_death,multikill_3_lmg_or_smg_hip_fire,killed_dog_close_to_teammate,multikill_2_zone_attackers,muiltikill_2_with_rcbomb,multikill_3_remote_missile,multikill_3_with_mgl,destroy_turret,call_in_3_care_packages,destroyed_helicopter_with_bullet,destroy_qrdrone,destroyed_qrdrone_with_bullet,destroy_helicopter,destroy_aircraft_with_emp,destroy_aircraft_with_missile_drone,perk_nottargetedbyairsupport_destroy_aircraft,destroy_aircraft,killstreak_10_no_weapons_perks,kill_with_resupplied_lethal_grenade,stun_aitank_with_emp_grenade", "," );
    self iprintlnbold( "^5UNLOCKING ALL CALLING CARDS..." );
    foreach ( challenge in challenges )
    {
        self addplayerstat( challenge, 10000 );
        wait 0.01;
    }
    self iprintlnbold( "^2ALL CALLING CARDS UNLOCKED" );
}

recovery_achievements( unused )
{
    trophies = strtok( "SP_COMPLETE_ANGOLA,SP_COMPLETE_MONSOON,SP_COMPLETE_AFGHANISTAN,SP_COMPLETE_NICARAGUA,SP_COMPLETE_PAKISTAN,SP_COMPLETE_KARMA,SP_COMPLETE_PANAMA,SP_COMPLETE_YEMEN,SP_COMPLETE_BLACKOUT,SP_COMPLETE_LA,SP_COMPLETE_HAITI,SP_VETERAN_PAST,SP_VETERAN_FUTURE,SP_ONE_CHALLENGE,SP_ALL_CHALLENGES_IN_LEVEL,SP_ALL_CHALLENGES_IN_GAME,SP_RTS_DOCKSIDE,SP_RTS_AFGHANISTAN,SP_RTS_DRONE,SP_RTS_CARRIER,SP_RTS_PAKISTAN,SP_RTS_SOCOTRA,SP_STORY_MASON_LIVES,SP_STORY_HARPER_FACE,SP_STORY_FARID_DUEL,SP_STORY_OBAMA_SURVIVES,SP_STORY_LINK_CIA,SP_STORY_HARPER_LIVES,SP_STORY_MENENDEZ_CAPTURED,SP_MISC_ALL_INTEL,SP_STORY_CHLOE_LIVES,SP_STORY_99PERCENT,SP_MISC_WEAPONS,SP_BACK_TO_FUTURE,SP_MISC_10K_SCORE_ALL,MP_MISC_1,MP_MISC_2,MP_MISC_3,MP_MISC_4,MP_MISC_5,ZM_DONT_FIRE_UNTIL_YOU_SEE,ZM_THE_LIGHTS_OF_THEIR_EYES,ZM_DANCE_ON_MY_GRAVE,ZM_STANDARD_EQUIPMENT_MAY_VARY,ZM_YOU_HAVE_NO_POWER_OVER_ME,ZM_I_DONT_THINK_THEY_EXIST,ZM_FUEL_EFFICIENT,ZM_HAPPY_HOUR,ZM_TRANSIT_SIDEQUEST,ZM_UNDEAD_MANS_PARTY_BUS,ZM_DLC1_HIGHRISE_SIDEQUEST,ZM_DLC1_VERTIGONER,ZM_DLC1_I_SEE_LIVE_PEOPLE,ZM_DLC1_SLIPPERY_WHEN_UNDEAD,ZM_DLC1_FACING_THE_DRAGON,ZM_DLC1_IM_MY_OWN_BEST_FRIEND,ZM_DLC1_MAD_WITHOUT_POWER,ZM_DLC1_POLYARMORY,ZM_DLC1_SHAFTED,ZM_DLC1_MONKEY_SEE_MONKEY_DOOM,ZM_DLC2_PRISON_SIDEQUEST,ZM_DLC2_FEED_THE_BEAST,ZM_DLC2_MAKING_THE_ROUNDS,ZM_DLC2_ACID_DRIP,ZM_DLC2_FULL_LOCKDOWN,ZM_DLC2_A_BURST_OF_FLAVOR,ZM_DLC2_PARANORMAL_PROGRESS,ZM_DLC2_GG_BRIDGE,ZM_DLC2_TRAPPED_IN_TIME,ZM_DLC2_POP_GOES_THE_WEASEL,ZM_DLC3_WHEN_THE_REVOLUTION_COMES,ZM_DLC3_FSIRT_AGAINST_THE_WALL,ZM_DLC3_MAZED_AND_CONFUSED,ZM_DLC3_REVISIONIST_HISTORIAN,ZM_DLC3_AWAKEN_THE_GAZEBO,ZM_DLC3_CANDYGRAM,ZM_DLC3_DEATH_FROM_BELOW,ZM_DLC3_IM_YOUR_HUCKLEBERRY,ZM_DLC3_ECTOPLASMIC_RESIDUE,ZM_DLC3_BURIED_SIDEQUEST,ZM_DLC4_ALL_YOUR_BASE,ZM_DLC4_PLAYING_WITH_POWER,ZM_DLC4_NOT_A_GOLD_DIGGER,ZM_DLC4_OVERACHIEVER,ZM_DLC4_TOMB_SIDEQUEST,ZM_DLC4_MASTER_WIZARD,ZM_DLC4_IM_ON_A_TANK,ZM_DLC4_KUNG_FU_GRIP,ZM_DLC4_MASTER_OF_DISGUISE,ZM_DLC4_SAVING_THE_DAY_ALL_DAY", "," );
    self iprintlnbold( "^5UNLOCKING ACHIEVEMENTS..." );
    foreach ( trophy in trophies )
    {
        self giveachievement( trophy );
        wait 0.05;
    }
    self iprintlnbold( "^2ALL ACHIEVEMENTS UNLOCKED" );
}

recovery_ranked_mode( unused )
{
    setdvar( "onlinegame", 1 );
    setdvar( "xblive_rankedmatch", 1 );
    setdvar( "xblive_privatematch", 0 );
    setdvar( "sv_forceunranked", 0 );
    self iprintlnbold( "^2RANKED MODE RE-APPLIED" );
}

recovery_save_profile( unused )
{
    self recovery_ranked_mode( 0 );
    self uploadstats();
    self iprintlnbold( "^2PROFILE SAVE SENT" );
}

recovery_save_end( unused )
{
    self recovery_save_profile( 0 );
    self iprintlnbold( "^2SAVED - ENDING GAME" );
    wait 1;
    level notify( "game_ended" );
    exitlevel( false );
}
