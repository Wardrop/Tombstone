Sequel.migration do
  up do
    add_column :allocation, :old_id, Integer, :null => true
    
    self << "
      INSERT INTO [allocation] ([TYPE]
        ,[PLACE_ID]
        ,[STATUS]
        ,[INTERMENT_TYPE]
        ,[FUNERAL_DIRECTOR_ID]
        ,[FUNERAL_DIRECTOR_NAME]
        ,[FUNERAL_SERVICE_LOCATION]
        ,[ADVICE_RECEIVED_DATE]
        ,[INTERMENT_DATE]
        ,[LOCATION_DESCRIPTION]
        ,[BURIAL_REQUIREMENTS]
        ,[COMMENTS]
        ,[MODIFIED_BY]
        ,[MODIFIED_AT]
        ,[CREATED_BY]
        ,[CREATED_AT]
        ,[OLD_ID])
      SELECT [TYPE]
          ,[PLACE_ID]
          ,[STATUS]
          ,[INTERMENT_TYPE]
          ,[FUNERAL_DIRECTOR_ID]
          ,[FUNERAL_DIRECTOR_NAME]
          ,[FUNERAL_SERVICE_LOCATION]
          ,[ADVICE_RECEIVED_DATE]
          ,[INTERMENT_DATE]
          ,[LOCATION_DESCRIPTION]
          ,[BURIAL_REQUIREMENTS]
          ,[COMMENTS]
          ,[MODIFIED_BY]
          ,[MODIFIED_AT]
          ,[CREATED_BY]
          ,[CREATED_AT]
          ,[ID]
      FROM [allocation]"
    
    self << "
      DELETE FROM [allocation]
      WHERE Old_Id IS NULL"
    
    self << "
      UPDATE [role_association]
      SET allocation_id = allocation.id
      FROM [role_association]
      INNER JOIN [allocation] ON role_association.allocation_id = allocation.old_id AND role_association.allocation_type = allocation.[type]"
    
    self << "
      UPDATE [transaction]
      SET allocation_id = allocation.id
      FROM [transaction]
      INNER JOIN [allocation] ON [transaction].allocation_id = allocation.old_id AND [transaction].allocation_type = allocation.[type]"
    
    self << "
      DELETE [role_association]
      FROM [role_association]
      LEFT JOIN [allocation] ON role_association.allocation_id = allocation.id
      WHERE allocation.id IS NULL"
    
    self << "
      DELETE [transaction]
      FROM [transaction]
      LEFT JOIN [allocation] ON [transaction].allocation_id = allocation.id
      WHERE allocation.id IS NULL"
    
    self << "
      UPDATE [transaction]
      SET allocation_id = allocation.id
      FROM [transaction]
      INNER JOIN [allocation] ON [transaction].allocation_id = allocation.old_id AND [transaction].allocation_type = allocation.[type]"
    
    drop_column :allocation, :old_id
    
    # Drop primary key on the transaction table
    self << "
      DECLARE @pkName Varchar(255)
  
      SET @pkName= (
          SELECT [name] FROM sysobjects
              WHERE [xtype] = 'PK'
              AND [parent_obj] = OBJECT_ID(N'[dbo].[transaction]')
      )
      DECLARE @dropSql varchar(4000)
  
      SET @dropSql=
          'ALTER TABLE [dbo].[transaction]
              DROP CONSTRAINT ['+@pkName+']'
      EXEC(@dropSql)"
    alter_table :transaction do
      add_primary_key [:allocation_id, :receipt_no]
    end
    # Drop primary key on the allocation table
    self << "
      DECLARE @pkName Varchar(255)
  
      SET @pkName= (
          SELECT [name] FROM sysobjects
              WHERE [xtype] = 'PK'
              AND [parent_obj] = OBJECT_ID(N'[dbo].[allocation]')
      )
      DECLARE @dropSql varchar(4000)
  
      SET @dropSql=
          'ALTER TABLE [dbo].[allocation]
              DROP CONSTRAINT ['+@pkName+']'
      EXEC(@dropSql)"

    alter_table :allocation do
      add_primary_key [:id]
    end
    drop_column :transaction, :allocation_type
    drop_column :role_association, :allocation_type
  end
end