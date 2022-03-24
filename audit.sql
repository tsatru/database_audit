CREATE OR REPLACE FUNCTION "public"."if_modified_biodiversity"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
DECLARE
    v_old_data hstore;
    v_new_data hstore;
    v_change_value hstore;
    v_old_value hstore;
    uuid_f text;
    occurrence_id_f text;
BEGIN
 
 
    IF (TG_OP = 'UPDATE') THEN  
        v_old_data := hstore(OLD.*);
        v_new_data := hstore(NEW.*);
        v_old_value := hstore(OLD.*) - v_new_data;
        v_change_value := hstore(NEW.*) - v_old_data;
        uuid_f := v_old_data -> 'uuid';
        occurrence_id_f := v_old_data -> 'occurrence_id';

        INSERT INTO "public".logged_actions (schema_name,table_name,user_name,action,query, "old_value", new_value, uuid, occurrence_id)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1), current_query(), v_old_value, v_change_value, uuid_f, occurrence_id_f);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := hstore(OLD.*);
uuid_f := v_old_data -> 'uuid';
        occurrence_id_f := v_old_data -> 'occurrence_id';
        INSERT INTO "public".logged_actions (schema_name,table_name,user_name,action,query,old_value,uuid, occurrence_id)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1), current_query(), v_old_data,uuid_f, occurrence_id_f);
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := hstore(NEW.*);
uuid_f := v_new_data -> 'uuid';
        occurrence_id_f := v_new_data -> 'occurrence_id';
        INSERT INTO "public".logged_actions (schema_name,table_name,user_name,action,query,new_value,uuid, occurrence_id)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1), current_query(),v_new_data,uuid_f, occurrence_id_f);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %',TG_OP,now();
        RETURN NULL;
    END IF;
 
EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;
