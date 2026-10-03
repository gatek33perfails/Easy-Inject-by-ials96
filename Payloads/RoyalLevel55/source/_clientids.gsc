init()
{
    level thread codex_level55_connect();
}

codex_level55_connect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread codex_level55_spawn();
    }
}

codex_level55_spawn()
{
    self endon( "disconnect" );
    self waittill( "spawned_player" );

    target = getdvar( "codex_level55_target" );
    if ( target != "*" && self.name != target )
        return;

    self.pers["rank"] = level.maxrank;
    self setdstat( "playerstatslist", "rank", "StatValue", level.maxrank );
    self.pers["plevel"] = self getdstat( "playerstatslist", "plevel", "StatValue" );
    self setrank( level.maxrank, self.pers["plevel"] );
    self iprintlnbold( "^6Level 55 Set!" );
    setdvar( "codex_level55_done", self.name );
}
