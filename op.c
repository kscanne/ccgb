#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <db.h>

void
cleanup (DB * dbp, int ret)
{
  int t_ret;

  if ((t_ret = dbp->close (dbp, 0)) != 0 && ret == 0)
    ret = t_ret;
  exit (ret);
}

int
main (int argc, char* argv[])
{
  DB *dbp;
  DBT key, data;
  int ret, len;
  char token[65535];
  char *split;

  if (argc != 2)
  {
   fprintf(stderr, "Usage: pptog dbfile\n");
   exit (1);
  }

  if ((ret = db_create (&dbp, NULL, 0)) != 0)
    {
      fprintf (stderr, "db_create: %s\n", db_strerror (ret));
      exit (1);
    }
  if ((ret =
       dbp->open (dbp, NULL, argv[1], NULL, DB_HASH, DB_CREATE, 0664)) != 0)
    {
      dbp->err (dbp, ret, "%s", argv[1]);
      cleanup (dbp, ret);
    }

  while (fgets (token, 65535, stdin) != NULL)
    {
      memset (&key, 0, sizeof (key));
      memset (&data, 0, sizeof (data));
//      printf ("read token=\"%s\"\n", token);
      split = strchr (token, ' ');
      if (split == NULL)
	{
	 split = strchr(token, '\n');
	 if (split == NULL) {
	      fprintf(stderr, "Neither a space nor a newline.\n");
	     }
	}
	  // keep null characters at end of all keys/data in db 
      key.size = split - token + 1;
      key.data = malloc (key.size);
      *split = 0;
      strcpy (key.data, token);
      len = strlen (split + 1);
      if (len > 0) {
          *(split + len) = 0;	/* was newline */
          data.size = len ;
          data.data = malloc (data.size);
          strcpy (data.data, split + 1);
	 }
      else {
          data.size = 1;
          data.data = malloc (1);
	  *((char*) data.data) = 0;
         }
      if ((ret = dbp->put (dbp, NULL, &key, &data, 0)) == 0) {
	 printf ("db: %s: key stored.\n", (char *) key.data);
	  ;
	}
      else
	{
	  dbp->err (dbp, ret, "DB->put");
	  cleanup (dbp, ret);
	}
      free (key.data);
      free (data.data);
    }

  cleanup (dbp, ret);
}
